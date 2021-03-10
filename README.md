# Circusd issue

This is a test setup that allows for testing with circusd, outlining a specific issue. It requires: `docker`, `docker-compose` and preferrably support for `bash` scripts.

## The problem

Circus can go haywire when something is wrong with the `cmd` inside the application' circus config file (eg `app3.ini`), specifically when it cannot find the process it should start. When circus cannot start the process (it returns immediately), it starts outputting errors at an unlimited rate, which breaks the mechanism that allows control of circus itself, requiring the circus daemon to be restarted, losing all control of all managed apps. That's not what should happen with a process manager...

So this is written to the log at a very high rate:
`circus[1] [WARNING] error in 'app3': [Errno 2] No such file or directory: '/srv/mine/app3-broken': '/srv/mine/app3-broken'`

But now the circusctl daemon is unresponsive to queries:

    $./exec.sh -c 'circusctl status'
    Timed out.
    A time out usually happens in one of those cases:

    #1 The Circus daemon could not be reached.
    #2 The Circus daemon took too long to perform the operation

    For #1, make sure you are hitting the right place
    by checking your --endpoint option.

    For #2, if you are not expecting a result to
    come back, increase your timeout option value
    (particularly with waiting switches)

Besides, this will also prevent other apps from starting because the circusd daemon is too occupied.

## Whats should have happened (IMHO)

- circusd should have stayed responsive to `circusctl` commands
- circusd should have kept trying to start app4 (according to the `max_retry` setting), but not as fast as possible, but with a (configured) "delay between startups"

## Reproduce the problem

    # Run the example. This will also tail the circusd output to the console.
    # Building it the first time can take a little while (sorry)
    # It will output a continuous stream of warning messages and circusd will be unresponsive
    # for circusctl commands
    ./run.sh

    # Open another terminal to enter the container:
    ./exec.sh

    # Now fire some commands to get the lay of the land
    circusctl list
    circusctl status

    # Optionally open yet another terminal and tail app logs directly to your console:
    ./exec.sh -c 'tail -f /srv/mine/app2/log/application.log'
    ./exec.sh -c 'tail -f /srv/mine/app2/log/circus.stdout.log'
    ./exec.sh -c 'tail -f /srv/mine/app3/log/circus.stderr.log'

## About the apps

- app1: Should work normally and not crash.
- app2: Starts normally, but fails to listen on port 8080, which is in use by app1. This app starts "flapping" and will be restarted endlessly every 7 seconds, which is what we want.
- app3: `cmd` points to a non-existing binary. The app cannot be started and circusd leaves it `stopped` after 5 tries, thanks to `max_retry = 5`.
- app4: `cmd` points to a non-existing binary. The app cannot be started, but circusd keeps trying visciously and forever because `max_retry = -1`. This however makes circusd unresponsive and fills up the circusd log at a very high rate.

## Disclaimer

This example is a bit bloated, but it helps me investigate issues, but also explore circusd.
