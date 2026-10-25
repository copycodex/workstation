/*
 * xkb-group — читает и ставит активную группу раскладки X11.
 *
 * Зачем свой бинарник. В apt Ubuntu 26.04 нет ни xkb-switch, ни
 * xkblayout-state, ни g3kb-switch — проверено, `apt-cache policy` пуст на всех
 * трёх. А `setxkbmap` для сброса не годится: перезагрузка карты оставляет
 * активной ту же группу (проверено 2026-08-20 — после `setxkbmap us,ru`
 * группа осталась 1). Группу двигает только XkbLockGroup из libX11, ради неё
 * эти тридцать строк и написаны.
 *
 *   xkb-group      печатает номер текущей группы (0 — первая в layout, us)
 *   xkb-group 0    включает первую раскладку
 *
 * Без DISPLAY выходит с нулём и молчит: по ssh и в неграфической сессии
 * переключать нечего, а зовут эту команду хуки агентов — падать им из-за
 * отсутствия X нельзя.
 */
#include <X11/XKBlib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int print_group(Display *display) {
  XkbStateRec state;

  if (XkbGetState(display, XkbUseCoreKbd, &state) != Success) {
    fprintf(stderr, "xkb-group: не удалось прочитать состояние XKB\n");
    return 1;
  }

  printf("%d\n", state.group);
  return 0;
}

static int lock_group(Display *display, const char *argument) {
  char *end = NULL;
  long group = strtol(argument, &end, 10);

  if (*argument == '\0' || *end != '\0' || group < 0 || group > 3) {
    fprintf(stderr, "xkb-group: номер группы — целое от 0 до 3, а не «%s»\n", argument);
    return 2;
  }

  XkbLockGroup(display, XkbUseCoreKbd, (unsigned int)group);
  XFlush(display);
  return 0;
}

int main(int argc, char **argv) {
  Display *display = NULL;
  int status = 0;

  if (argc > 2) {
    fprintf(stderr, "использование: xkb-group [номер группы]\n");
    return 2;
  }

  if (getenv("DISPLAY") == NULL) {
    return 0;
  }

  display = XOpenDisplay(NULL);
  if (display == NULL) {
    fprintf(stderr, "xkb-group: не открывается дисплей %s\n", getenv("DISPLAY"));
    return 1;
  }

  status = (argc == 2) ? lock_group(display, argv[1]) : print_group(display);

  XCloseDisplay(display);
  return status;
}
