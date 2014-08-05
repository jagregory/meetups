# Meetups of the Week

Script to build the base of a Meetups of the Week email.

Pulls all Tech meetups from meetup.com for the next week, strips out any groups in blacklist.txt, highlights ones we're hosting or attending, and the groups them by day.

Prints it as markdown.

## Usage

    API_KEY=YOUR_MEETUP_KEY ./upcoming --help

    Usage: upcoming [options]
        --all                        Don't use a blacklist
        --raw                        Raw output, no markdown
    -c, --city CITY                  Meetup city (default: Sydney)
    -b, --blacklist FILE             Meetup blacklist file (default: blacklist.txt)
        --highlight FILE             Attendees to highlight (default: users.yml)
    -f, --fast                       Don't highlight notable attendees
        --category N                 Meetup.com category ID (default: 34)
    -v, --verbose                    Log debug info
        --emoji                      Use emoji for icons

By default it will do the right thing (mostly).

Fancy:

    API_KEY=YOUR_MEETUP_KEY ./upcoming | pandoc -f markdown -t html | bcat
