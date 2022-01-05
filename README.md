# Ant Nuptial Flight Predictor

A basic Flutter application with an Android home screen app widget. Works on Android, IOS and Web.

Ant Nuptial Flight Predictor downloads the weather in your current location and gives you the rough
likelihood that queen ants are flying near you today and for the next week. When the percentage is
high, time to get outside and looking for ants in your local area!

<img src="https://raw.githubusercontent.com/bradrushworth/nuptialflight/master/assets/Screenshot_1641349717.png" height="540" /> <img src="https://raw.githubusercontent.com/bradrushworth/nuptialflight/master/assets/Screenshot_1641349723.png" width="540" />

## Getting Started

Build in Android Studio.

The following commands were useful:

flutter pub pub run flutter_automation --android-sign flutter packages pub run
flutter_launcher_icons:main flutter --no-color build appbundle

You'll need to create a file at assets/.env with a line for free 
your https://home.openweathermap.org/api_keys key:
OPENWEATHERMAP_API_KEY=<your secret key>

## Attribution

Code forked from https://github.com/ashgarg143/AppWidgetFlutter

<a href="https://iconscout.com/icons/ant" target="_blank">Ant Icon</a>
by <a href="https://iconscout.com/contributors/vladyslav-severyn">Vladyslav Severyn</a>
on <a href="https://iconscout.com">Iconscout</a>
