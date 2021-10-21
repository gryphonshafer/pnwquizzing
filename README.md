# PNW Bible Quizzing

[![test](https://github.com/gryphonshafer/pnwquizzing/workflows/test/badge.svg)](https://github.com/gryphonshafer/pnwquizzing/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/pnwquizzing/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/pnwquizzing)

Web site, documents, statistics, and tools in support of the **PNW Bible
Quizzing** program.

## Setup

To setup an instance of the web site, first install and setup the
[Omniframe](https://github.com/gryphonshafer/omniframe) project as per its
instructions. Then clone this project to a desired location. Typically, this is
in parallel to the `omniframe` project root directory.

Change directory to the project root directory, and run the following:

    cpanm -n -f --installdeps .

## Run

To run the web site application, follow the instructions in the `~/app.psgi`
file within the project's root directory.

## Photo Optimization

Within `~/static/photos` reside many JPG photo image files. These are
automatically picked up and displayed at random across most rendered pages.
Use the following procedure to optimize photos prior to add/commit:

    for file in $( ls *.{jpg,png,gif} 2> /dev/null )
    do
        name=$(echo $file | sed 's/\.[^\.]*$//')
        convert $file -resize 440\> $name.jpg
    done
    rm *.{png,gif}
    jpegoptim -s *.jpg

Requires:

- `imagemagick`
- `jpegoptim`
