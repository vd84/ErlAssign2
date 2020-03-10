%%%-------------------------------------------------------------------
%%% @author doha6991
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. mars 2020 10:02
%%%-------------------------------------------------------------------
-module(bank).
-author("doha6991").

%% API
-export([start/0, balance/2, deposit/3, withdraw/3, lend/4]).




start() ->
  Pid = spawn(fun() -> bank(#{a => 1}) end),
  register(bank, Pid),
  on_error(Pid, fun(Pid, Why) -> io:format("pid: ~p failed with error: ~p~n", [Pid, Why]) end),
  Pid.

on_error(Pid, On_error) ->
  spawn(fun() -> Reference = monitor(process, Pid),
    io:format("Reference: ~p", [Reference]),
    receive
      {'DOWN', Reference, process, Pid, Why} ->
        demonitor(Reference),
        unregister(bank),
        On_error(Pid, Why),
        io:format("I (parent) My worker ~p died (~p)~n", [Pid, Why]),
        start()

    end
        end).

bank(Accounts) ->
  receive
    {Pid, Ref, Account1} ->
      case maps:is_key(Account1, Accounts) of
        true ->
          Pid ! {Ref, is_number(maps:get(Account1, Accounts)), maps:get(Account1, Accounts)},
          bank(Accounts);
        false ->
          Pid ! {Ref, not_found},
          bank(maps:put(Account1, 0, Accounts))
      end;
    {Pid, Ref, Amount, Operation, Account} ->
      case Operation of
        deposit ->
          case maps:is_key(Account, Accounts) of
            true ->
              Pid ! {Ref, true, Amount},
              bank(maps:put(Account, maps:get(Account, Accounts) + Amount, Accounts));
            false ->
              Pid ! {Ref, not_found},
              bank(maps:put(Account, 0, Accounts))
          end;
%Withdraw
        withdraw ->
          case maps:is_key(Account, Accounts) of
            true ->
              Pid ! {Ref, true, maps:get(Account, Accounts) - Amount},
              bank(maps:put(Account, maps:get(Account, Accounts) - Amount, Accounts));
            false ->
              Pid ! {Ref, not_found},
              bank(maps:put(Account, 0, Accounts))
          end
      end;
    {Pid, Ref, Amount, _Operation, Account1, Account2} ->


      case maps:is_key(Account1, Accounts) or maps:is_key(Account2, Accounts) of
        true ->
          case maps:is_key(Account1, Accounts) of
            true ->
              case maps:is_key(Account2, Accounts) of
                true ->
                  Pid ! {Ref, ok},
                  bank(maps:put(Account2, maps:get(Account2, Accounts) + Amount, maps:put(Account1, maps:get(Account1, Accounts) - Amount, Accounts)));
                false ->
                  Pid ! {Ref, false, Account2},
                  bank(maps:put(Account2, 0, Accounts))

              end;
            false ->
              Pid ! {Ref, false, Account1},
              bank(maps:put(Account1, 0, Accounts))

          end;
        false ->
          Pid ! {Ref, both}
      end
  end.

balance(Pid, Account) ->
  Ref = make_ref(),
  Pid ! {self(), Ref, Account},
  receive
    {Ref, not_found} ->
      no_account;
    {Ref, true, Number} ->
      Number
  end.

deposit(Pid, Account, Amount) ->
  Ref = make_ref(),
  Pid ! {self(), Ref, Amount, deposit, Account},
  receive
    {Ref, not_found} ->
      no_account;
    {Ref, true, Number} ->
      {ok, Number}
  end.

withdraw(Pid, Account, Amount) ->
  Ref = make_ref(),
  Pid ! {self(), Ref, Amount, withdraw, Account},
  receive
    {Ref, not_found} ->
      no_account;
    {Ref, true, Number} ->
      {ok, Number}
  end.

lend(Pid, From, To, Amount) ->
  Ref = make_ref(),
  Pid ! {self(), Ref, Amount, lend, From, To},
  receive
    {Ref, ok} ->
      ok;
    {Ref, false, Account} ->
      {no_account, Account};
    {Ref, both} ->
      both

  end.

