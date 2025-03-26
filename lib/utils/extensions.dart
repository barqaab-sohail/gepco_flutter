extension ExtString on String{

  bool get isValidEmail {

    final emailRegExp = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}");
    return emailRegExp.hasMatch(this);
  }


  bool get isValidPassword{

    final passwordRegExp = RegExp(r"^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,}");
    return passwordRegExp.hasMatch(this);
  }

  bool get isValidLatitude {
    final latitudeRegExp = RegExp(r"^-?([0-8]?[0-9]|90)(\.[0-9]{1,10})");
    return latitudeRegExp.hasMatch(this);
  }

  bool get isValidLongitude {
    final longitudeRegExp = RegExp(r"^-?([0-9]{1,2}|1[0-7][0-9]|180)(\.[0-9]{1,10})");
    return longitudeRegExp.hasMatch(this);
  }

}