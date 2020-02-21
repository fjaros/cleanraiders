cleanraiders -- README
=================

cleanraiders is a World of Warcraft Classic v1.13 addon for raid assignments. The external program downloads a Google spreadsheet which the addon can broadcast to the raid in game.

Written by Munchkin \<clean\> on Fairbanks-US.

**Always go to [releases](https://github.com/fjaros/cleanraiders/releases) to download the latest compiled version!**

## Download spreadsheet

* Spreadsheet template is https://docs.google.com/spreadsheets/d/1XKRdlqtCvwPdv6X0WlNclvLY9B1js0oYqZ0cvepTB3w . Make a copy of the spreadsheet and edit as desired. The template MUST stay the same so the addon can read it!

* Run `cleanraiders.jar` . You must have at least Java 1.8 installed on your system.
   * It will try to guess wher your World of Warcraft is installed. You can also click the WoW icon to enter a directory manually.
   * Paste your spreadsheet URL into the bottom field. Click Go!

![example1](https://raw.githubusercontent.com/fjaros/cleanraiders/master/images/example1.png)

## Run the addon

* Move cleanraiders directory into `World of Warcraft\_classic_\Interface\AddOns`
* In game, the addon will show up as a skull icon on the minimap edge. Sheets will labeled by time downloaded with most recent ones listed first.
* Clicking the Send button will send the row to Raid chat. Ex: Tank assignments for each mob.
* Clicking any raid marker will send the column to Raid chat. Ex: Which group stands in which corner on Razorgore.
* The **Sync** button allows for a raid leader or assistant to send his sheet to other users of the addon in the Raid.

![example2](https://raw.githubusercontent.com/fjaros/cleanraiders/master/images/example2.png)

## Compile
1. cleanraiders is written in Java and compiles using [maven](https://maven.apache.org).
2. It uses Java JDK 1.8.
3. Run `mvn clean package` which will produce a file in the target folder called `cleanraiders.jar`.
4. Double click `cleanraiders.jar` or run `java -jar cleanraiders.jar`.
