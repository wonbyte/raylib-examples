#include <stdlib.h>
#include "raylib.h"

int main(void) {
  const int screenWidth = 800;
  const int screenHeight = 450;

  InitWindow(screenWidth, screenHeight, "raylib [core] example -basic windwos");

  // Set the game to run at 60 frames-per-second
  SetTargetFPS(60);

  // Main game loop
  while (!WindowShouldClose())  // Detect window close button or ESC key
  {
    // Draw
    BeginDrawing();

    ClearBackground(RAYWHITE);

    DrawText("Congrates! You cretaed your first window!", 190, 200, 20,
             LIGHTGRAY);

    EndDrawing();
  }

  // Close window and OpenGL context
  CloseWindow();

  return EXIT_SUCCESS;
}
