%%%-------------------------------------------------------------------
%%% @author doha6991
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. mars 2020 10:02
%%%-------------------------------------------------------------------
-module(double).
-author("doha6991").

%% API
-export([start/0]).


start() ->
  Pid = spawn(fun doubler/0),
  register(double, Pid).



doubler() ->
  receive
    {Pid, Ref, N} ->
      Pid ! {Ref, N * 2},
      doubler()

  end.

