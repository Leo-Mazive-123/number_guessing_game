#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate random number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Get username
echo "Enter your username:"
read USERNAME

# Check if user exists
USER_INFO=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_INFO ]]; then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username, games_played) VALUES('$USERNAME', 0)" > /dev/null
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
else
  # Existing user
  USER_ID=$(echo $USER_INFO | cut -d'|' -f1)
  GAMES_PLAYED=$(echo $USER_INFO | cut -d'|' -f2)
  BEST_GAME=$(echo $USER_INFO | cut -d'|' -f3)
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Guessing loop
echo "Guess the secret number between 1 and 1000:"
NUMBER_OF_GUESSES=0

while true; do
  read GUESS

  # Check if input is an integer
  if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  (( NUMBER_OF_GUESSES++ ))

  if (( GUESS < SECRET_NUMBER )); then
    echo "It's higher than that, guess again:"
  elif (( GUESS > SECRET_NUMBER )); then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

    # Update database
    CURRENT=$($PSQL "SELECT games_played, best_game FROM users WHERE user_id=$USER_ID")
    GAMES=$(echo $CURRENT | cut -d'|' -f1)
    BEST=$(echo $CURRENT | cut -d'|' -f2)

    NEW_GAMES=$(( GAMES + 1 ))

    if [[ -z $BEST ]] || (( NUMBER_OF_GUESSES < BEST )); then
      $PSQL "UPDATE users SET games_played=$NEW_GAMES, best_game=$NUMBER_OF_GUESSES WHERE user_id=$USER_ID" > /dev/null
    else
      $PSQL "UPDATE users SET games_played=$NEW_GAMES WHERE user_id=$USER_ID" > /dev/null
    fi

    break
  fi
done