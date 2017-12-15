# ImageScraper

A google image scraper written in Julia. Although this was done largely as an exercise to learn Julia, it is functional if you want to use it. It exports the function image_scrape which takes search term(s) (a string or array of strings), a number of images of each to scrape of google images, and the paths to put them in. Built with Selenium and Julia. No parallelism implementing yet so may be slow depending on connection.

[![Build Status](https://travis-ci.org/bmillidgework/ImageScraper.jl.svg?branch=master)](https://travis-ci.org/bmillidgework/ImageScraper.jl)

[![Coverage Status](https://coveralls.io/repos/bmillidgework/ImageScraper.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/bmillidgework/ImageScraper.jl?branch=master)

[![codecov.io](http://codecov.io/github/bmillidgework/ImageScraper.jl/coverage.svg?branch=master)](http://codecov.io/github/bmillidgework/ImageScraper.jl?branch=master)
