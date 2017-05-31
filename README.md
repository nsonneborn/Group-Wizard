# Group Wizard
[Group Wizard](https://nsonneborn.shinyapps.io/group-wizard/) is an RStudio Shiny App for assigning groups based on ranked preferences. CSV files must be of the same format as the example files included in this repository, including headers. `example_choices.csv` corresponds to the CSV of individuals' preferences and `example_capacities` corresponds to the CSV of group capacities. These should be interpreted as MAXIMUM capacities.

This app was originially built for [Farm Camp at Plantation, CA](http://plantationcamp.com/), where campers are assigned to an aminal chore each week, ranging from milking cows, helping with the kittens, or chopping wood. Before the week starts, they give their top 4 choices of the ~15 chores and staff does their best to give each camper a chore they would like to do. Examples are given in this context.

This is app is new, and I intend to make the following improvements:
* Generalize so that the number of choices given can range from 1 to Inf, rather than exactly 4
* Add in selection functionality for interpreting `capacity` in the CSV of group capacities as either exact capacity, minimum capacity, or maximum capacity.
* Aesthetic improvements and including instructions in the app.
