congreso: ¿Quién es Quién?
==========================

Historical data of the spanish congress from 1979 up to february 2014

###Introduction

The spanish congress website has a lot of historical information inside covering the period from 1979 up to date.

Altough this information is scattered around the site making it difficult to get a sense of what is going on or make comparative analysis on the provided data.

This repo tries to tackle the analysis problem in order to work with the data itself during the 2014 Open Data Day.

###Scrapers

Developed to extract the information from the [spanish congress][1]

[1]: http://www.congreso.es 

###DB

Includes the schema file and a complete dump of a postgres DB created from the data extracted by the scrapers.

* Create a local postgresql database (`createdb congreso`)
* import the schema file into the new database
* import the data file into the new database




