#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read -r USERNAME

# Get user info (games_played, best_game)
USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")

# If user does not exist
if [[ -z $USER_INFO ]]
then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_USER=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  GAMES_PLAYED=0
  BEST_GAME=0
else
  GAMES_PLAYED=$(echo $USER_INFO | cut -d '|' -f1)
  BEST_GAME=$(echo $USER_INFO | cut -d '|' -f2)

  # Fix empty best_game
  if [[ -z $BEST_GAME ]]
  then
    BEST_GAME=0
  fi

  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate secret number
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
GUESS_COUNT=0

echo "Guess the secret number between 1 and 1000:"

while true
do
  read -r GUESS

  # Validate integer
  if ! [[ $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi

  ((GUESS_COUNT++))

  if [[ $GUESS -lt $SECRET_NUMBER ]]
  then
    echo "It's higher than that, guess again:"
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"

    NEW_GAMES=$((GAMES_PLAYED + 1))

    # Update best game correctly
    if [[ $BEST_GAME -eq 0 || $GUESS_COUNT -lt $BEST_GAME ]]
    then
      $PSQL "UPDATE users SET games_played=$NEW_GAMES, best_game=$GUESS_COUNT WHERE username='$USERNAME'"
    else
      $PSQL "UPDATE users SET games_played=$NEW_GAMES WHERE username='$USERNAME'"
    fi

    break
  fi
done
