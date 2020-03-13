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
  Pid = spawn(fun() -> bank(#{}) end),
  on_error(Pid),
  Pid.

on_error(Pid) ->
  spawn(fun() -> Reference = monitor(process, Pid),
    receive
      {'DOWN', Reference, process, Pid, _Why} ->
        demonitor(Reference),
        no_bank
    end
        end).

bank(Accounts) ->
  %balance
  receive
    {Pid, Ref, Account1} ->
      Pid ! {Ref, maps:get(Account1, Accounts, no_account)},
      bank(Accounts);
%Deposit/withdraw
    {Pid, Ref, Amount, MathFun, Account, Operation} ->
      case Operation of
        deposit ->
          NewAccounts = maps:put(Account, MathFun(maps:get(Account, Accounts, 0), Amount), Accounts),
          Pid ! {Ref, maps:get(Account, NewAccounts)},
          bank(NewAccounts);
        withdraw ->
          case maps:is_key(Account, Accounts) of
            true ->
              case MathFun(maps:get(Account, Accounts, 0), Amount) >= 0 of
                true ->
                  NewAccounts = maps:update(Account, MathFun(maps:get(Account, Accounts, 0), Amount), Accounts),
                  Pid ! {Ref, maps:get(Account, NewAccounts)},
                  bank(NewAccounts);
                false ->
                  Pid ! {Ref, insufficient_funds},
                  bank(Accounts)
              end;
            false ->
              Pid ! {Ref, no_account},
              bank(Accounts)
          end
      end;

%Lend
    {Pid, Ref, Amount, Account1, Account2} ->
      case maps:is_key(Account1, Accounts) or maps:is_key(Account2, Accounts) of
        true ->
          case maps:is_key(Account1, Accounts) of
            true ->
              case maps:is_key(Account2, Accounts) of
                true ->
                  AmountLeft = maps:get(Account1, Accounts) - Amount,
                  case AmountLeft >= 0 of
                    true ->
                      Pid ! {Ref, ok},
                      bank(maps:put(Account2, maps:get(Account2, Accounts) + Amount, maps:put(Account1, maps:get(Account1, Accounts) - Amount, Accounts)));
                    false ->
                      Pid ! {Ref, insufficient_funds},
                      bank(Accounts)
                  end;

                false ->
                  Pid ! {Ref, false, Account2},
                  bank(Accounts)
              end;
            false ->
              Pid ! {Ref, false, Account1},
              bank(maps:put(Account1, 0, Accounts))
          end;
        false ->
          Pid ! {Ref, both},
          bank(Accounts)

      end
  end.



balance(Pid, Account) ->
  Ref = make_ref(),
  Pid ! {self(), Ref, Account},
  receive
    {Ref, no_account} ->
      no_account;
    {Ref, Balance} ->
      {ok, Balance}
  end.

deposit(Pid, Account, Amount) ->
  Ref = make_ref(),
  Pid ! {self(), Ref, Amount, fun(X, Y) -> X + Y end, Account, deposit},
  receive
    {Ref, Number} ->
      {ok, Number}
  end.

withdraw(Pid, Account, Amount) ->
  Ref = make_ref(),
  Pid ! {self(), Ref, Amount, fun(X, Y) -> X - Y end, Account, withdraw},
  receive
    {Ref, no_account} ->
      no_account;
    {Ref, insufficient_funds} ->
      insufficient_funds;
    {Ref, Number} ->
      {ok, Number}

  end.

lend(Pid, From, To, Amount) ->
  Ref = make_ref(),
  Pid ! {self(), Ref, Amount, From, To},
  case is_pid(Pid) of
    true ->
      receive
        {Ref, insufficient_funds} ->
          insufficient_funds;
        {Ref, ok} ->
          ok;
        {Ref, both} ->
          {no_account, both};
        {Ref, false, Account} ->
          {no_account, Account};
        false ->
          no_bank
      end
  end.



