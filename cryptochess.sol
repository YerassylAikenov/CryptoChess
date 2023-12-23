// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Import the ERC20 interface from the OpenZeppelin library
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ChessGame contract to facilitate chess games with bets
contract ChessGame {
    address public tokenAddress; // Address of the ERC20 token used for bets

    // Mapping to track the game IDs for each player
    mapping(address => uint256) public playerGameIDs;

    // Structure to represent a chess game
    struct Game {
        address player1;      // Address of player 1
        address player2;      // Address of player 2
        uint256 betAmount;    // Amount of tokens bet on the game
        bool isCompleted;     // Flag indicating if the game is completed
        address winner;       // Address of the winner
    }

    // Mapping to store games using their unique IDs
    mapping(uint256 => Game) public games;

    // Event emitted when a new game is created
    event NewGameCreated(uint256 gameID, address player1, address player2, uint256 betAmount);

    // Event emitted when a move is made in a game
    event MoveMade(uint256 gameID, address player, bytes32 move);

    // Event emitted when a game is completed
    event GameCompleted(uint256 gameID, address winner);

    // Constructor to initialize the token address
    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    // Function to create a new chess game
    function createGame(address _player2, uint256 _betAmount) public {
        require(_betAmount > 0, "Bet amount must be greater than zero");
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), _betAmount), "Failed to transfer bet amount");

        // Increment the game ID for the players and set it for both players
        uint256 gameID = playerGameIDs[msg.sender] + 1;
        playerGameIDs[msg.sender] = gameID;
        playerGameIDs[_player2] = gameID;

        // Create a new game and store it in the mapping
        games[gameID] = Game({
            player1: msg.sender,
            player2: _player2,
            betAmount: _betAmount,
            isCompleted: false,
            winner: address(0)
        });

        // Emit an event to notify that a new game has been created
        emit NewGameCreated(gameID, msg.sender, _player2, _betAmount);
    }

    // Function for a player to make a move in a game
    function makeMove(uint256 _gameID, bytes32 _move) public {
        require(games[_gameID].isCompleted == false, "Game has already been completed");
        require(msg.sender == games[_gameID].player1 || msg.sender == games[_gameID].player2, "Invalid player");

        // Emit an event to record the move made by a player
        emit MoveMade(_gameID, msg.sender, _move);
    }

    // Function to complete a chess game and determine the winner
    function completeGame(uint256 _gameID, address _winner) public {
        require(games[_gameID].isCompleted == false, "Game has already been completed");
        require(games[_gameID].winner == address(0), "Winner has already been determined");
        require(msg.sender == games[_gameID].player1 || msg.sender == games[_gameID].player2, "Invalid player");

        // Mark the game as completed and set the winner
        games[_gameID].isCompleted = true;
        games[_gameID].winner = _winner;

        // Transfer the bet amount to the winner
        IERC20(tokenAddress).transfer(_winner, games[_gameID].betAmount);

        // Emit an event to signal the completion of the game
        emit GameCompleted(_gameID, _winner);
    }
}
