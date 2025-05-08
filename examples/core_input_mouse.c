#include <stdlib.h>
#include "raylib.h"

int main(void) {
  const int screenWidth = 800;
  const int screenHeight = 450;

  InitWindow(screenWidth, screenHeight, "raylib [core] example - mouse input");

  Vector2 ballPosition = {-100.0f, -100.0f};
  Color ballColor = DARKBLUE;
  int isCursorHidden = 0;

  SetTargetFPS(60);

  while (!WindowShouldClose()) {
    if (IsKeyPressed(KEY_H)) {
      if (isCursorHidden == 0) {
        HideCursor();
        isCursorHidden = 1;
      } else {
        ShowCursor();
        isCursorHidden = 0;
      }
    }

    ballPosition = GetMousePosition();

    if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT))
      ballColor = MAROON;
    else if (IsMouseButtonPressed(MOUSE_BUTTON_MIDDLE))
      ballColor = LIME;
    else if (IsMouseButtonPressed(MOUSE_BUTTON_SIDE))
      ballColor = PURPLE;
    else if (IsMouseButtonPressed(MOUSE_BUTTON_EXTRA))
      ballColor = YELLOW;
    else if (IsMouseButtonPressed(MOUSE_BUTTON_FORWARD))
      ballColor = ORANGE;
    else if (IsMouseButtonPressed(MOUSE_BUTTON_BACK))
      ballColor = BEIGE;

    BeginDrawing();

    ClearBackground(RAYWHITE);

    DrawCircleV(ballPosition, 40, ballColor);

    DrawText("move the ball with mouse and click button to change color", 10,
             10, 20, DARKGRAY);
    DrawText("Press 'H' to toggle cursor visibility", 10, 30, 20, DARKGRAY);

    if (isCursorHidden == 1)
      DrawText("CURSOR HIDDEN", 20, 60, 20, RED);
    else
      DrawText("CURSOR VISIBLE", 20, 60, 20, LIME);

    EndDrawing();
  }

  CloseWindow();

  return EXIT_SUCCESS;
}
