class Crate {
  float x, y, r, vx, vy;
  boolean aTerra;
  boolean estavaSobreTrampoli;

  Crate(float _x, float _y, float _r) {
    x = _x;
    y = _y;
    r = _r;
  }

  void update(boolean pA, boolean pB, boolean pC) {
    vy += gravetatForca * dirGravetat;
    vx *= friccio;
    boolean sobreTrampoli = grid[int(y/TILE_SIZE)][int(x/TILE_SIZE)] == TRAMPOLINE;
    if (sobreTrampoli) {
      if (!estavaSobreTrampoli) activaAnimacioTrampoli(x, y);
      vy = -12 * dirGravetat;
    }
    estavaSobreTrampoli = sobreTrampoli;

    if (pucMoure(x + vx, y, pA, pB, pC)) {
      float oldX = x;
      x += vx;
      for (Crate a : caixes) {
        if (a != this && a.estaSobre(this)) a.x += (x - oldX);
      }
      for (InterruptorGrav ig : interruptorsGrav) {
        if (ig.estaSobreC(this)) ig.x += (x - oldX);
      }
    } else {
      vx = 0;
    }

    boolean sobreSuport = false;
    if (contacteSuportPerGravetat(x, y, r, vy, pare.x, pare.y, pare.r)) {
      y = yCentratSobreSuport(pare.y, pare.r, r);
      vy = pare.vy;
      sobreSuport = true;
    }

    for (Crate a : caixes) {
      if (a != this && contacteSuportPerGravetat(x, y, r, vy, a.x, a.y, a.r)) {
        y = yCentratSobreSuport(a.y, a.r, r);
        vy = a.vy;
        sobreSuport = true;
      }
    }
    for (InterruptorGrav ig : interruptorsGrav) {
      if (contacteSuportPerGravetat(x, y, r, vy, ig.x, ig.y, ig.r)) {
        y = yCentratSobreSuport(ig.y, ig.r, r);
        vy = ig.vy;
        sobreSuport = true;
      }
    }

    if (!sobreSuport) {
      if (pucMoure(x, y + vy, pA, pB, pC)) {
        y += vy;
        aTerra = false;
      } else {
        if (bloqueigMapaVertical(y + vy, pA, pB, pC)) {
          ajustaYFinsContacte(vy, pA, pB, pC);
        }
        aTerra = true;
        vy = 0;
      }
    } else {
      aTerra = true;
    }
  }

  boolean estaSobre(Crate s) {
    if (!solapamentHoritzEntre(x, r, s.x, s.r)) return false;
    if (dirGravetat == 1) return abs((y + r) - (s.y - s.r)) < 5;
    return abs((y - r) - (s.y + s.r)) < 5;
  }

  boolean estaSobreInterruptor(InterruptorGrav ig) {
    if (!solapamentHoritzEntre(x, r, ig.x, ig.r)) return false;
    if (dirGravetat == 1) return abs((y + r) - (ig.y - ig.r)) < 5;
    return abs((y - r) - (ig.y + ig.r)) < 5;
  }

  void mourePerSuport(float dx, float dy, boolean pA, boolean pB, boolean pC) {
    if (!pucMoure(x + dx, y + dy, pA, pB, pC)) return;

    x += dx;
    y += dy;
    for (Crate a : caixes) {
      if (a != this && a.estaSobre(this)) {
        a.mourePerSuport(dx, dy, pA, pB, pC);
      }
    }
    for (InterruptorGrav ig : interruptorsGrav) {
      if (ig.estaSobreC(this)) {
        ig.mourePerSuport(dx, dy, pA, pB, pC);
      }
    }
  }

  boolean pucMoure(float nx, float ny, boolean pA, boolean pB, boolean pC) {
    float m = r * 0.92;
    if (!comprovarColisio(nx-m, ny-m, pA, pB, pC) || !comprovarColisio(nx+m, ny-m, pA, pB, pC) ||
        !comprovarColisio(nx-m, ny+m, pA, pB, pC) || !comprovarColisio(nx+m, ny+m, pA, pB, pC)) {
      return false;
    }
    if (rectIntersect(nx-r, ny-r, r*2, r*2, fill.x-fill.r, fill.y-fill.r, fill.r*2, fill.r*2)) {
      return false;
    }
    for (InterruptorGrav ig : interruptorsGrav) {
      if (rectIntersect(nx-r, ny-r, r*2, r*2, ig.x-ig.r, ig.y-ig.r, ig.r*2, ig.r*2)) return false;
    }
    return true;
  }

  boolean bloqueigMapaVertical(float ny, boolean pA, boolean pB, boolean pC) {
    float m = r * 0.92;
    return !comprovarColisio(x-m, ny-m, pA, pB, pC) || !comprovarColisio(x+m, ny-m, pA, pB, pC) ||
           !comprovarColisio(x-m, ny+m, pA, pB, pC) || !comprovarColisio(x+m, ny+m, pA, pB, pC);
  }

  void ajustaYFinsContacte(float vyIntentat, boolean pA, boolean pB, boolean pC) {
    float signe = vyIntentat >= 0 ? 1 : -1;
    float pas = 0.25 * signe;
    int guard = 0;
    while (guard < 200 && pucMoure(x, y + pas, pA, pB, pC)) {
      y += pas;
      guard++;
    }
  }

  boolean comprovarColisio(float px, float py, boolean pA, boolean pB, boolean pC) {
    int c = floor(px / TILE_SIZE);
    int f = floor(py / TILE_SIZE);
    if (f < 0 || f >= ROWS || c < 0 || c >= COLS) return false;
    int t = grid[f][c];
    if (t == WALL || (t == DOOR_A && !pA) || (t == DOOR_B && !pB) || (t == DOOR_C && !pC)) return false;
    return true;
  }

  void display() {
    pushMatrix();
    translate(x, y);
    if (imgCaja != null && imgCaja.width > 0) {
      imageMode(CENTER);
      image(imgCaja, 0, 0);
      imageMode(CORNER);
    } else {
      fill(#8B5A2B);
      stroke(#5C3A21);
      strokeWeight(2);
      rect(-r, -r, r*2, r*2, 4);
      line(-r, -r, r, r);
      line(r, -r, -r, r);
    }
    popMatrix();
  }
}
