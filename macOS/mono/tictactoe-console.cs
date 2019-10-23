//
// Tic Tac Toe Implementation of a decent algorithm
// that make you shine in your next interview.
//
// Console application runs on Mac OSX/Linux with Mono and Windows
//
using System;


namespace TicTacToe
{
    public static class Program
    {
        public static void Main(string[] args)
        {
            Console.WriteLine("** Game Starting");
                TttNums.main();
            Console.WriteLine("** Game Ended");
        }
    }

    public class TttNums {
        private static bool[] board;  //the tic-tac-toe board
        private String name;
        private bool trying;
        private bool[] taken;
        private bool[] pairs;
        static TttNums[] player;

        public static void main()
        {
            player = new TttNums[2];
            player[0] = new TttNums("Toto");
            player[1] = new TttNums("Molly");
            
            int who = 1; //player numbers are 1 and 0 
            board = new bool[10]; //only 1-9 are used 
            
            for (int k = 0; k < 9 && player[0].isTrying() && player[1].isTrying(); k++)
            {
                player[who].move();
                printBoard();
                who = 1 - who;    //now it’s the other player’s turn
            } //for
        } //main

        //
        // A very basic Tic Tac Toe board
        //
        public static void printBoard()
        {
            printSquare(8);
            printSquare(1);
            printSquare(6);
            Console.WriteLine("\n--------------------");
            printSquare(3);
            printSquare(5);
            printSquare(7);
            Console.WriteLine("\n--------------------");
            printSquare(4);
            printSquare(9);
            printSquare(2);
            Console.WriteLine("\n\n");
        } //printBoard

        //
        // 
        //
        public static void printSquare(int spot)
        {
            // fill one square for board
            int who = -1;
            if (player[0].isTaken(spot))
                who = 0;
            else if (player[1].isTaken(spot))
                who = 1;
            if (who < 0)
                Console.Write("|     ");
            else
                Console.Write("| " + player[who].getName() + " ");
        }//printSquare

        //
        // Get player name
        //
        public String getName()
        {
            return name;
        }//getName

        //
        // Is the selected location taken?
        //
        public bool isTaken(int spot)
        {
            return taken[spot];
        }

        //
        // Player stops trying after winning
        //
        public bool isTrying()
        {
            return trying;
        }//isTrying

        //
        // Class Constructor
        //
        public TttNums(String name)
        {
            taken = new bool[10];
            pairs = new bool[16];
            trying = true;
            this.name = name;
        } //constructor

        //
        // Game playing strategy goes here - this version makes random moves
        //
        public void move() { //make a random move
            int spot;
            do
            { //find an empty board location
                spot = (int) new Random().Next(9) + 1;
            } while (board[spot]);
            
            Console.WriteLine(name + ": move to " + spot); 
            if (pairs[15 - spot]) { //check for a win
                Console.WriteLine(name + "!!!WIN!!!");
                trying = false;
            }
            else
            {
                for (int j = 1; j < 10; j++) { 
                    
                    //update pairs array 
                if (taken[j] && j + spot < 15) {
                    pairs[j + spot] = true;
                    
                    // this helps you to understand what's going on in the back stage
                    Console.WriteLine(">>>>>>> " + name +"  setting " + (j+spot));
                }
                }
            }
        taken[spot] = board[spot] = true;
        }//move
    }
}
