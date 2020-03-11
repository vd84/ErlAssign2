%%%-------------------------------------------------------------------
%%% @author doha6991
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. mars 2020 10:02
%%%-------------------------------------------------------------------
-module(monitor).
-author("doha6991").

%% API
-export([start/0]).


start() ->
  Pid = double:start(),
  io:format("Hello: ~p", [Pid]),
  on_error(Pid, fun(Pid2, Why) -> io:format("pid: ~p failed with error: ~p~n", [Pid2, Why]) end).

on_error(Pid, On_error) ->
  spawn(fun() -> Reference = monitor(process, Pid),
    io:format("Reference: ~p", [Reference]),
    receive
      {'DOWN', Reference, process, Pid, Why} ->
        demonitor(Reference),
        On_error(Pid, Why),
        io:format("I (parent) My worker ~p died (~p)~n", [Pid, Why]),
        start()

    end
        end).






