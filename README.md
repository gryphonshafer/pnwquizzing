# PNW Bible Quizzing

[![test](https://github.com/gryphonshafer/pnwquizzing/workflows/test/badge.svg)](https://github.com/gryphonshafer/pnwquizzing/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/pnwquizzing/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/pnwquizzing)

Web site, documents, statistics, and tools in support of the **PNW Bible
Quizzing** program.

## Installation and Setup

This project requires the [Omniframe](https://github.com/gryphonshafer/omniframe)
project, which is expected to be deployed in a parallel directory. Follow the
instructions in the Omniframe README "Installation" and "Project Setup" sections.

## Run Application

To run the project application, follow the instructions in the `~/app.psgi`
file within this project's root directory.

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
