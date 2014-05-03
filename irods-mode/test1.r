acSetRescSchemeForCreate {
  msiSetDefaultResc("null", "noForce");
}

printHello {
  on($userNameClient == "rods") {
    print_message("Hello Mr.$userNameClient");
    print_message("How are you?");
  }
}

printHello {
  print_message("Hello $userNameClient");
}

printHello {
  print_hello;
}
