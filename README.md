# Ant Nuptial Flight Predictor

A basic Flutter application with an Android home screen app widget. Works on Android, IOS and Web.

Demo: https://nuptialflight.codemagic.app/

Ant Nuptial Flight Predictor downloads the weather in your current location and gives you the rough
likelihood that queen ants are flying near you today and for the next week. When the percentage is
high, time to get outside and looking for ants in your local area!

<img src="https://raw.githubusercontent.com/bradrushworth/nuptialflight/master/assets/Screenshot_1641349717.png" height="540" /> <img src="https://raw.githubusercontent.com/bradrushworth/nuptialflight/master/assets/Screenshot_1641349723.png" width="540" />

## The Science

* [Weather conditions during nuptial flight of Manica rubida](https://antwiki.org/wiki/images/5/50/Depa%2C_L._2006._Weather_conditions_during_nuptial_flight_of_Manica_rubida.pdf)
* [The spatial distribution and environmental triggers of ant mating flights](https://onlinelibrary.wiley.com/doi/epdf/10.1111/ecog.03140)
* [Weather Conditions During Nuptial Flights of Four European Ant Species](https://www.antwiki.org/wiki/images/d/dd/Boomsma%2C_J.J.%2C_Leusink%2C_A._1981._Weather_conditions_during_nuptial_flights_of_four_European_ant_species_.pdf)

## Getting Started

Build in Android Studio.

The following commands were useful:

```
flutter pub pub run flutter_automation --android-sign
flutter packages pub run flutter_launcher_icons:main
flutter --no-color build appbundle
```

Dependency upgrade instruction:

```
flutter pub upgrade --major-versions
```

You'll need to create a file at assets/.env with a line:

```
OPENWEATHERMAP_API_KEY=<your secret key>
```

setting your free https://home.openweathermap.org/api_keys key.

## Attribution

Code originally forked from https://github.com/ashgarg143/AppWidgetFlutter

Thanks for the <a href="https://iconscout.com/icons/ant" target="_blank">Ant Icon</a>
by <a href="https://iconscout.com/contributors/vladyslav-severyn">Vladyslav Severyn</a>
on <a href="https://iconscout.com">Iconscout</a>.
