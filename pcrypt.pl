#!/usr/bin/perl

#pCrypt - Perl Frontend to various encryption utilites
#Licensed under the GNU GPLv3
#Copyright Shawn Anastasio 2014

#Settings (You probably shouldn't touch these)
$version = "0.1a"; # Version
@validc = ("aes-256-cbc", "bcrypt"); # Available Ciphers
$numValidCiphers = $#ARGV + 1; # Number of Available Ciphers
$cipher = $ARGV[1]; # Second argument is cipher (only used w/ -c)
$selectedCipher = 0; # Default to having no custom cipher selected


# Let's get the number of arguments provided
$num_args = $#ARGV + 1;

# Go to error/help if no arguments are provided
if ($num_args eq 0) {
  help();
}


# Go to error/help sub on -h or --help

if ($ARGV[0] eq "-h" || $ARGV[0] eq "--help") {
  help();
};

# Handle -l/--list
if ($ARGV[0] eq "-l" || $ARGV[0] eq "--list") {
  listciphers();
};

# Handle -c/--ciphers
if ($ARGV[0] eq "-c" || $ARGV[0] eq "--ciphers") {
  # If no cipher is specified, direct user to -l
  if ($ARGV[1] eq "") {
    die("Error, no cipher specified.\nSee -l for available ciphers\n");
  } else { # Else continue
    # Let's make sure they selected a valid cipher
    ciphercheck();

    # If selection is valid, continue
    if ($selectValid eq 1) {
      # I may add things here later
    } else { # else exit and tell user to -l
      die("Error, invalid cipher specified.\nSee -l for available ciphers\n");
    };
  };
  # At this point we now have a valid $cipher if applicable
  # Lets mark that we have selected a cipher so it can be dealt with later on
  $selectedCipher = 1;

  # If -e/--encrypt is selected, let's send them there
  if ($ARGV[2] eq "-e" || $ARGV[2] eq "--encrypt")  {
    encrypt();
  };

  # Likewise for -d/--decrypt
  if ($ARGV[2] eq "-d" || $ARGV[2] eq "--decrypt") {
    decrypt();
  };
};

# Handle -e/--encrypt
if ($ARGV[0] eq "-e" || $ARGV[0] eq "--encrypt") {
  encrypt();
};

# Handle -d/--decrypt
if ($ARGV[0] eq "-d" || $ARGV[0] eq "--decrypt") {
  decrypt();
};

# Handle encryption
sub encrypt {
  # First, lets check if a cipher is specified
  # If not, we can assume aes-256-cbc
  if ($selectedCipher eq 0) {
    print("Warning: No cipher specified. Defaulting to aes-256-cbc\n");
    $cipher = "aes-256-cbc";
    # Since -c wasn't specified, we can assume
    # that the file is the 2nd argument
    $file = $ARGV[1];
  } else {
    # Since -c was specfied, the file should be
    # the 4th argument
    $file = $ARGV[3];
  };

  # If aes-256-cbc is selected, send them there
  if ($cipher eq "aes-256-cbc") {
    aes256cbcE();
  };

  # Likewise for bcrypt
  if ($cipher eq "bcrypt") {
    bcryptE();
  };

  # Die gracefully
  die("\n");
};

# Handle decryption
sub decrypt {
  # First, lets check if a cipher is specified
  # We need one specified to determine how to decrypt
  # This will eventually be done automatically

  if ($selectedCipher eq 0) {
    die("ERROR: You must select a cipher with -c")
  } else {
    # Since -c was specfied, the file should be
    # the 4th argument
    $file = $ARGV[3];
  };

  # If aes-256-cbc is selected, send them there
  if ($cipher eq "aes-256-cbc") {
    aes256cbcD();
  };

  # Likewise for bcrypt
  if ($cipher eq "bcrypt") {
    bcryptD();
  };

  # Die gracefully
  die("\n");
};

# Handle encryption w/ aes-256-cbc
sub aes256cbcE {
  print("Beginning encryption with cipher aes-256-cbc\n");

  $sslE = system("openssl aes-256-cbc -salt -in $file -out $file.tmp");

  # If the encryption failed (ex. typo in password), it should return not 0

  if ($sslE eq 0) { # Upon success, we can get rid of temp file
    system("mv -f $file.tmp $file");
    system("mv $file $file.paes");
    print("Success! The encrypted file has been saved as $file.paes\n");
  } else {
    die("ERROR: File encryption failed.\n");
  }


  # Die gracefully
  die("\n");
};

# Handle encryption w/ bcrypt
sub bcryptE {
  print("Beginning encryption with cipher bcrypt\n");
  system("bcrypt $file");
  $test = qx(file \'$file.bfe\'); # Test to make sure encryption succeded

  if ($test ne "") {
    print("Success! The encrypted file has been saved as $file.bfe\n");
  } else {
    die("ERROR: Encryption has failed\n");
  };

  # Die gracefully
  die("\n");
};

# Handle decryption w/ aes-256-cbc
sub aes256cbcD {

  $sslD = system("openssl aes-256-cbc -d -in $file -out $file.tmp");

  # If the decryption failed (ex. typo in password), it should return not 0

  if ($sslD eq 0) { # Upon success, we can get rid of temp file
    $newfile = $file;
    chop $newfile; # Get rid of .paes
    chop $newfile;
    chop $newfile;
    chop $newfile;
    chop $newfile;
    system("mv -f $file.tmp $file");
    system("mv $file $newfile");
    print("Success! The decrypted file has been saved as $newfile\n");
  } else {
    system("rm -f $file.tmp");
    die("ERROR: File encryption failed.\n");
  }



  # Die gracefully
  die("\n");
};

# Handle decryption w/ bcrypt
sub bcryptD {
  print("Beginning decrption with cipher bcrypt\n");

  system("bcrypt $file");
  $test = qx(file \'$file\');
  if ($test ne "") {
    $newfile = $file;
    chop $newfile; # Let's get rid of the .bfe
    chop $newfile;
    chop $newfile;
    chop $newfile;

    print("Success! The encrypted file has been saved as $newfile\n");
  }

  # Die gracefully
  die("\n");
};


# Grab all available ciphers
# Will eventually fix this to read from array
sub listciphers {
  print("Available Ciphers:\n\n");
  print("aes-256-cbc  (via OpenSSL, salted)\n");
  print("bcrypt  (via bcrypt commandline utility)\n");
  print("\n");
};

# Confirm that selected cipher is valid
sub ciphercheck {
  # By default assume that the selected cipher is invalid
  $selectValid = 0;

  # Check selected cipher against every valid one in array
  # I should probably find a better way to do this
  for ($i = 0;$i <= $numValidCiphers;$i++) {
    if ($cipher eq $validc[$i]) {
      # If there is a match, lets mark a correct choice
      $selectValid = 1;
    };
  };
};

# Let's print out some info about the program
sub help {
  print("pCrypt v$version\n");
  print("\nUsage: pcrypt [-c (cipher)] [options] [file]\n");
  print("  -h  --help    Display this screen\n");
  print("  -v  --version    Display the version\n");
  print("  -e --encrypt [file]   Encrypt the file provided\n");
  print("  -d --decrypt [file]   Decrypt the file provided\n");
  print("  -c --cipher [cipher]   Perform task with selected cipher\n");
  print("  -l  --list    List available ciphers\n");
  print("\nExamples:\n");
  print("  pcrypt -c bcrypt -e MyFile.txt\n");
  print("  pcrypt -c bcrypt -d MyFile.txt.bfe\n");
};