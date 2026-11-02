program PowerTimerTests;

{ Console test runner. Runs all tests by default:
    PowerTimerTests            plain text output
    PowerTimerTests --help     other options (e.g. --format=xml) }

{$mode objfpc}{$H+}

uses
  Classes, consoletestrunner,
  TimerLogicTests;

var
  App: TTestRunner;

begin
  DefaultRunAllTests := True;
  DefaultFormat := fPlain;
  App := TTestRunner.Create(nil);
  try
    App.Initialize;
    App.Title := 'Power Timer tests';
    App.Run;
  finally
    App.Free;
  end;
end.
