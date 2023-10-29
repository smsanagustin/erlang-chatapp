-module(chat).
-export([init_chat/0, receiver/1, init_chat2/1, sendMessage/3]).

init_chat() ->
    UserInput = io:get_line("Enter your name: "),
    % remove \n
    UserName = string:strip(UserInput, both, $\n), 
    register(receiver, spawn(chat, receiver, [UserName])).

receiver(UserName) ->
    receive
        % when user receives bye, chat will be terminated
        bye ->
            io:format("You partner has disconnected!~n");

        {"", UserName2, Sender_Pid} ->
            io:format("You are now connected to ~s.~n", [UserName2]),

            % allow reply from the current user
            io:format("~s", [UserName]),
            Reply = io:get_line(": "),

            % send reply to the other user
            Sender_Pid ! {Reply, UserName, self()};

        {Message, UserName2, Sender_Pid} ->
            % receiver will print on the terminal the message it received
            io:format("~s: ~s~n", [UserName2, Message]),

            % get reply from the current user when it received a message:
            Reply = io:get_line("~s: ", [UserName]),

            % send reply and current user to the sender
            Sender_Pid ! {Reply, UserName, self()},
            receiver(UserName)
    end.

% ReceiverNode is the node of the user you want to send a message to
init_chat2(ReceiverNode) ->
    % get user's name
    UserInput2 = io:get_line("Enter your name: "),
    % remove \n
    UserName2 = string:strip(UserInput2, both, $\n), 

    % send an empty string initially to connect two nodes
    spawn(chat, sendMessage, ["", UserName2, ReceiverNode]).

% if sender sends a "bye" message, bye will be sent to receiver; chat will end
sendMessage("bye", UserName2, ReceiverNode) ->
    UserName2 = UserName2,
    {receiver, ReceiverNode} ! bye,
    io:format("ok");

% used to send message to the other user
sendMessage(Message, UserName2, ReceiverNode) ->
    % send Message to receiver
    {receiver, ReceiverNode} ! {Message, UserName2, self()},

    % check if there are replies from the receiver
    receive
        {Reply, UserName, ReceiverNode} ->
            io:format("received a reply!~n"),
            io:format("~s: ~s~n", [UserName, Reply])
    end,

    % after getting a reply from the receiver, get user input to send another message
    io:format("~s", [UserName2]),
    NewMessage = io:get_line(": "),
    sendMessage(NewMessage, UserName2, ReceiverNode).