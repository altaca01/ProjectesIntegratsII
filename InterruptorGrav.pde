class InterruptorGrav {
  float x, y, r, vx, vy;
  boolean aTerra;
  boolean estavaSobreTrampoli;

  InterruptorGrav(float _x, float _y, float _r) {
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
      for (InterruptorGrav o : interruptorsGrav) {
        if (o != this && o.estaSobre(this)) o.x += (x - oldX);
      }
      for (Crate c : caixes) {
        if (contacteSuportPerGravetat(c.x, c.y, c.r, c.vy, x, y, r)) {
          c.x += (x - oldX);
          for (Crate a : caixes) {
            if (a != c && a.estaSobre(c)) a.mourePerSuport(x - oldX, 0, pA, pB, pC);
          }
        }
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
    for (Crate c : caixes) {
      if (contacteSuportPerGravetat(x, y, r, vy, c.x, c.y, c.r)) {
        y = yCentratSobreSuport(c.y, c.r, r);
        vy = c.vy;
        sobreSuport = true;
      }
    }
    for (InterruptorGrav o : interruptorsGrav) {
      if (o != this && contacteSuportPerGravetat(x, y, r, vy, o.x, o.y, o.r)) {
        y = yCentratSobreSuport(o.y, o.r, r);
        vy = o.vy;
        sobreSuport = true;
      }
    }

    if (!sobreSuport) {
      if (pucMoure(x, y + vy, pA, pB, pC)) {
        y += vy;
        aTerra = false;
      } else {
        aTerra = true;
        vy = 0;
      }
    } else {
      aTerra = true;
    }
  }

  boolean estaSobre(InterruptorGrav s) {
    if (!solapamentHoritzEntre(x, r, s.x, s.r)) return false;
    if (dirGravetat == 1) return abs((y + r) - (s.y - s.r)) < 5;
    return abs((y - r) - (s.y + s.r)) < 5;
  }

  boolean estaSobreC(Crate c) {
    if (!solapamentHoritzEntre(x, r, c.x, c.r)) return false;
    if (dirGravetat == 1) return abs((y + r) - (c.y - c.r)) < 5;
    return abs((y - r) - (c.y + c.r)) < 5;
  }

  void mourePerSuport(float dx, float dy, boolean pA, boolean pB, boolean pC) {
    if (!pucMoure(x + dx, y + dy, pA, pB, pC)) return;
    x += dx;
    y += dy;
    for (InterruptorGrav o : interruptorsGrav) {
      if (o != this && o.estaSobre(this)) o.mourePerSuport(dx, dy, pA, pB, pC);
    }
  }

  boolean pucMoure(float nx, float ny, boolean pA, boolean pB, boolean pC) {
    float m = r * 0.8;
    if (!comprovarColisio(nx-m, ny-m, pA, pB, pC) || !comprovarColisio(nx+m, ny-m, pA, pB, pC) ||
        !comprovarColisio(nx-m, ny+m, pA, pB, pC) || !comprovarColisio(nx+m, ny+m, pA, pB, pC)) {
      return false;
    }
    if (rectIntersect(nx-r, ny-r, r*2, r*2, pare.x-pare.r, pare.y-pare.r, pare.r*2, pare.r*2)) {
      return false;
    }
    if (rectIntersect(nx-r, ny-r, r*2, r*2, fill.x-fill.r, fill.y-fill.r, fill.r*2, fill.r*2)) {
      return false;
    }
    for (Crate c : caixes) {
      if (rectIntersect(nx-r, ny-r, r*2, r*2, c.x-c.r, c.y-c.r, c.r*2, c.r*2)) return false;
    }
    for (InterruptorGrav o : interruptorsGrav) {
      if (o != this && rectIntersect(nx-r, ny-r, r*2, r*2, o.x-o.r, o.y-o.r, o.r*2, o.r*2)) return false;
    }
    return true;
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
    float H = 14;
    float cy = (dirGravetat == 1) ? (r - 1 - H * 0.5f) : (-r + 1 + H * 0.5f);
    dibuixaBasePedestal(cy, H);
    if (dirGravetat == 1) {
      dibuixaOnesBlaus(cy - H * 0.5f - 8, -1);
    } else {
      dibuixaOnesBlaus(cy + H * 0.5f + 8, 1);
    }
    popMatrix();
  }

  /** Peana escalonada (dos graons), només fill + contorn. */
  void dibuixaPeana(float cy, float H) {
    float Wb = TILE_SIZE * 0.60f;
    float Wt = Wb * 0.88f;
    float yUnio = cy + H * 0.19f;
    if (dirGravetat == 1) {
      float yTerra = r - 0.5f;
      float totalH = max(6.0f, yTerra - yUnio);
      float h1 = totalH * 0.60f;
      float h2 = totalH - h1;
      float yJ = yTerra - h1;

      noStroke();
      fill(32, 48, 60);
      rect(-Wb * 0.5f, yJ, Wb, h1);
      rect(-Wt * 0.5f, yUnio, Wt, h2);

      noFill();
      stroke(55, 95, 115);
      strokeWeight(1.8f);
      beginShape();
      vertex(-Wb * 0.5f, yTerra);
      vertex(Wb * 0.5f, yTerra);
      vertex(Wb * 0.5f, yJ);
      vertex(Wt * 0.5f, yJ);
      vertex(Wt * 0.5f, yUnio);
      vertex(-Wt * 0.5f, yUnio);
      vertex(-Wt * 0.5f, yJ);
      vertex(-Wb * 0.5f, yJ);
      endShape(CLOSE);
    } else {
      float ySostre = -r + 0.5f;
      float yUnioInv = cy - H * 0.19f;
      float totalH = max(6.0f, yUnioInv - ySostre);
      float h1 = totalH * 0.60f;
      float h2 = totalH - h1;

      noStroke();
      fill(32, 48, 60);
      rect(-Wb * 0.5f, ySostre, Wb, h1);
      rect(-Wt * 0.5f, ySostre + h1, Wt, h2);

      noFill();
      stroke(55, 95, 115);
      strokeWeight(1.8f);
      beginShape();
      vertex(-Wb * 0.5f, ySostre);
      vertex(Wb * 0.5f, ySostre);
      vertex(Wb * 0.5f, ySostre + h1);
      vertex(Wt * 0.5f, ySostre + h1);
      vertex(Wt * 0.5f, yUnioInv);
      vertex(-Wt * 0.5f, yUnioInv);
      vertex(-Wt * 0.5f, ySostre + h1);
      vertex(-Wb * 0.5f, ySostre + h1);
      endShape(CLOSE);
    }
    noStroke();
  }

  /** Base circular estil pedestal (inspiració sci-fi), tons coherents amb el mapa. */
  void dibuixaBasePedestal(float cy, float H) {
    dibuixaPeana(cy, H);
    float W = TILE_SIZE * 0.58f;

    noStroke();
    fill(18, 32, 42, 210);
    ellipse(0, cy + 1.2f, W + 5, H * 0.36f + 2);

    fill(38, 58, 74);
    ellipse(0, cy, W + 3, H * 0.34f);

    noFill();
    stroke(45, 175, 230, 200);
    strokeWeight(2);
    ellipse(0, cy, W, H * 0.30f);

    noStroke();
    fill(52, 78, 98);
    ellipse(0, cy, W - 4, H * 0.26f);

    fill(28, 48, 62);
    ellipse(0, cy - 0.8f, W * 0.52f, H * 0.16f);

    int n = 8;
    for (int k = 0; k < n; k++) {
      float ang = TWO_PI * k / n + frameCount * 0.018f;
      float rx = cos(ang) * (W * 0.36f);
      float ry = sin(ang) * (H * 0.10f);
      fill(110, 230, 255, 185);
      circle(rx, cy + ry, 2.2f);
    }

    float puls = 0.55f + 0.45f * (0.5f + 0.5f * sin(frameCount * 0.08f));
    if (dirGravetat == 1) {
      fill(70, 200, 255, (int)(40 * puls));
      triangle(-W * 0.15f, cy - H * 0.12f, W * 0.15f, cy - H * 0.12f, 0, cy - H * 0.12f - 18 * puls);
      fill(70, 200, 255, (int)(22 * puls));
      triangle(-W * 0.22f, cy - H * 0.1f, W * 0.22f, cy - H * 0.1f, 0, cy - H * 0.1f - 12 * puls);
    } else {
      fill(70, 200, 255, (int)(40 * puls));
      triangle(-W * 0.15f, cy + H * 0.12f, W * 0.15f, cy + H * 0.12f, 0, cy + H * 0.12f + 18 * puls);
      fill(70, 200, 255, (int)(22 * puls));
      triangle(-W * 0.22f, cy + H * 0.1f, W * 0.22f, cy + H * 0.1f, 0, cy + H * 0.1f + 12 * puls);
    }
  }

  void dibuixaOnesBlaus(float yBase, int sentit) {
    noFill();
    strokeWeight(3.6);

    float t = frameCount * 0.12;
    for (int i = 0; i < 3; i++) {
      float fase = t + i * 0.9;
      float offset = sin(fase) * 1.7 * sentit;
      float yAnell = yBase + i * 6 * sentit;
      float w = 9 + i * 4;
      float h = 3 + i * 2;

      // Aura neó més brillant
      stroke(70, 220, 255, 200);
      ellipse(0, yAnell + offset, w + 3, h + 3);

      // Traç principal cian-neó
      stroke(160, 255, 255);
      ellipse(0, yAnell + offset, w, h);

      // Traç intern més fi i lleugerament més fosc
      stroke(70, 220, 255, 200);
      strokeWeight(1.4);
      ellipse(0, yAnell + offset, w - 2.2, h - 1.4);
      strokeWeight(3.6);

      // Partícules neó en bucle, amb trajecte pseudoaleatori cap als costats i cap amunt
      float cicle1 = (frameCount * 0.018 + i * 0.27) % 1.0;
      float cicle2 = (frameCount * 0.021 + 0.35 + i * 0.19) % 1.0;

      float px1 = lerp(0, (i % 2 == 0 ? 1 : -1) * (w * 0.9 + 4), cicle1);
      px1 += sin((cicle1 * TWO_PI * 2.3) + i * 1.4) * 2.2;
      float py1 = yAnell + offset - cicle1 * 12 - sin((cicle1 * TWO_PI * 1.7) + i) * 1.5;

      float px2 = lerp(0, (i % 2 == 0 ? -1 : 1) * (w * 0.75 + 6), cicle2);
      px2 += cos((cicle2 * TWO_PI * 2.0) + i * 0.8) * 1.8;
      float py2 = yAnell + offset - cicle2 * 10 - cos((cicle2 * TWO_PI * 1.5) + i * 1.2) * 1.3;

      noStroke();
      fill(120, 255, 255, 230);
      circle(px1, py1, 3.4);
      fill(120, 255, 255, 120);
      circle(px1, py1, 5.6);
      fill(120, 255, 255, 230);
      circle(px2, py2, 3.0);
      fill(120, 255, 255, 120);
      circle(px2, py2, 5.0);
      noFill();
    }

    noStroke();
  }
}
