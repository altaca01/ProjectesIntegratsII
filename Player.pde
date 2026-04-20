class Player {
  float x, y, r, vx, vy;
  color col;
  boolean esFill, aTerra;
  boolean enganxatAlPare;
  boolean estavaSobreTrampoli;

  Player(float _x, float _y, float _r, color _c, boolean _h) {
    x = _x;
    y = _y;
    r = _r;
    col = _c;
    esFill = _h;
  }

  void update(boolean pA, boolean pB, boolean pC, Player altre) {
    float ax = 0;
    float speed = esFill ? TILE_SIZE * 0.015 : TILE_SIZE * 0.011;
    float jump = esFill ? TILE_SIZE * 0.25 : TILE_SIZE * 0.22;
    boolean esMouLateralment = false;
    boolean volSaltar = false;

    if (!esFill) {
      if (keys['a'] || keys['A']) ax -= speed;
      if (keys['d'] || keys['D']) ax += speed;
      if ((keys['w'] || keys['W']) && aTerra) {
        vy = -jump * dirGravetat;
        aTerra = false;
      }
    } else {
      if (keysCode[LEFT]) {
        ax -= speed;
        esMouLateralment = true;
      }
      if (keysCode[RIGHT]) {
        ax += speed;
        esMouLateralment = true;
      }
      if (keysCode[UP] && aTerra) {
        volSaltar = true;
        vy = -jump * dirGravetat;
        aTerra = false;
        enganxatAlPare = false;
      }
    }

    if (esFill && enganxatAlPare && !esMouLateralment && !volSaltar) {
      vx = 0;
    } else {
      vx = (vx + ax) * friccio;
    }
    vy += gravetatForca * dirGravetat;

    boolean sobreTrampoli = grid[int(y/TILE_SIZE)][int(x/TILE_SIZE)] == TRAMPOLINE;
    if (sobreTrampoli) {
      if (!estavaSobreTrampoli) activaAnimacioTrampoli(x, y);
      vy = -15 * dirGravetat;
      aTerra = false;
    }
    estavaSobreTrampoli = sobreTrampoli;

    if (pucMoure(x + vx, y, pA, pB, pC)) {
      x += vx;
    } else {
      vx = 0;
    }
    
    boolean sobreSuport = false;
    for (Crate c : caixes) {
      if (contacteSuportPerGravetat(x, y, r, vy, c.x, c.y, c.r)) {
        y = yCentratSobreSuport(c.y, c.r, r);
        vy = c.vy;
        sobreSuport = true;
        moureHoritzontalSegur(c.vx * 0.8, pA, pB, pC);
      }
    }
    for (InterruptorGrav ig : interruptorsGrav) {
      if (contacteSuportPerGravetat(x, y, r, vy, ig.x, ig.y, ig.r)) {
        y = yCentratSobreSuport(ig.y, ig.r, r);
        vy = ig.vy;
        sobreSuport = true;
        moureHoritzontalSegur(ig.vx * 0.8, pA, pB, pC);
      }
    }
    if (esFill && altre != null) {
      boolean solapatEnX = solapamentHoritzEntre(x, r, altre.x, altre.r);
      boolean aterrantSobre = contacteSuportPerGravetat(x, y, r, vy, altre.x, altre.y, altre.r);

      if (enganxatAlPare && (!solapatEnX || esMouLateralment || volSaltar)) {
        enganxatAlPare = false;
      }

      if (aterrantSobre) {
        enganxatAlPare = true;
      }

      if (enganxatAlPare && solapatEnX) {
        if (!esMouLateralment && !volSaltar) {
          x = altre.x;
          vx = 0;
        }
        y = yCentratSobreSuport(altre.y, altre.r, r);
        vy = altre.vy;
        sobreSuport = true;
        if (esMouLateralment) {
          x += altre.vx * 0.8;
        }
      }
    }

    if (!sobreSuport) {
      if (pucMoure(x, y + vy, pA, pB, pC)) {
        y += vy;
        aTerra = false;
      } else {
        if (velocitatTocaBloc(vy)) aTerra = true;
        vy = 0;
      }
    } else {
      aTerra = true;
    }
  }

  boolean pucMoure(float nx, float ny, boolean pA, boolean pB, boolean pC) {
    float m = r * 0.8;
    if (!comprovarColisio(nx-m, ny-m, pA, pB, pC) || !comprovarColisio(nx+m, ny-m, pA, pB, pC) ||
        !comprovarColisio(nx-m, ny+m, pA, pB, pC) || !comprovarColisio(nx+m, ny+m, pA, pB, pC)) {
      return false;
    }

    for (Crate c : caixes) {
      if (rectIntersect(nx-r, ny-r, r*2, r*2, c.x-c.r, c.y-c.r, c.r*2, c.r*2)) {
        if (esFill) return false;

        float pushX = nx - x;
        if (c.pucMoure(c.x + pushX, c.y, pA, pB, pC)) {
          c.x += pushX;
          for (Crate a : caixes) {
            if (a != c && a.estaSobre(c)) {
              a.mourePerSuport(pushX, 0, pA, pB, pC);
            }
          }
          for (InterruptorGrav ig : interruptorsGrav) {
            if (ig.estaSobreC(c)) ig.mourePerSuport(pushX, 0, pA, pB, pC);
          }
          return true;
        }
        return false;
      }
    }
    for (InterruptorGrav ig : interruptorsGrav) {
      if (rectIntersect(nx-r, ny-r, r*2, r*2, ig.x-ig.r, ig.y-ig.r, ig.r*2, ig.r*2)) {
        // Si estem recolzats sobre l'interruptor, permetem desplaçament lateral
        // per evitar quedar "enganxats" en sortir-ne.
        boolean movimentHoritz = abs(ny - y) < 0.001f;
        boolean sobreInterruptor;
        if (dirGravetat == 1) {
          sobreInterruptor = abs((y + r) - (ig.y - ig.r)) < 6;
        } else {
          sobreInterruptor = abs((y - r) - (ig.y + ig.r)) < 6;
        }
        if (!(movimentHoritz && sobreInterruptor)) {
          return false;
        }
      }
    }
    return true;
  }

  void moureHoritzontalSegur(float dx, boolean pA, boolean pB, boolean pC) {
    if (abs(dx) < 0.0001f) return;
    if (pucMoure(x + dx, y, pA, pB, pC)) {
      x += dx;
      return;
    }
    float signe = dx > 0 ? 1 : -1;
    float pas = 0.25f * signe;
    float mogut = 0;
    int guard = 0;
    while (abs(mogut + pas) <= abs(dx) && guard < 200 && pucMoure(x + pas, y, pA, pB, pC)) {
      x += pas;
      mogut += pas;
      guard++;
    }
  }

  boolean comprovarColisio(float px, float py, boolean pA, boolean pB, boolean pC) {
    int c = floor(px / TILE_SIZE);
    int f = floor(py / TILE_SIZE);
    if (f < 0 || f >= ROWS || c < 0 || c >= COLS) return false;
    int t = grid[f][c];
    if (t == WALL) return false;
    if (t == GAP) {
      boolean meitatSuperior = py % TILE_SIZE < TILE_SIZE / 2.0;
      if (meitatSuperior) return false;
    }
    if ((t == DOOR_A && !pA) || (t == DOOR_B && !pB) || (t == DOOR_C && !pC)) return false;
    return true;
  }

  void display() {
    noStroke();
    fill(col);
    rect(x-r, y-r, r*2, r*2, 4);
    fill(255);
    float ey = dirGravetat == 1 ? y-r+4 : y+r-12;
    rect(x-r+4, ey, 5, 5);
    rect(x+r-9, ey, 5, 5);
  }
}
