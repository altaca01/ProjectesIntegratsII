void aplicarSpawnDesIndex(int idx) {
  if (pare == null || fill == null) return;
  float[] def = { 1.5f, 1.5f, 4.5f, 1.5f };
  float[] s = def;
  if (spawnNivells != null && idx >= 0 && idx < spawnNivells.length) {
    float[] row = spawnNivells[idx];
    if (row != null && row.length >= 4) s = row;
  }
  pare.x = s[0] * TILE_SIZE;
  pare.y = s[1] * TILE_SIZE;
  fill.x = s[2] * TILE_SIZE;
  fill.y = s[3] * TILE_SIZE;
  pare.vx = pare.vy = 0;
  fill.vx = fill.vy = 0;
  pare.aTerra = false;
  pare.estavaSobreTrampoli = false;
  fill.aTerra = false;
  fill.estavaSobreTrampoli = false;
  fill.enganxatAlPare = false;
}

void carregarNivellDesIndex(int idx) {
  if (NIVELLS == null || idx < 0 || idx >= NIVELLS.length) return;
  int[][] src = NIVELLS[idx];
  for (int f = 0; f < ROWS; f++) {
    for (int c = 0; c < COLS; c++) {
      if (f < src.length && c < src[0].length) {
        int v = src[f][c];
        if (v == 12) v = 11;
        grid[f][c] = v;
      } else {
        grid[f][c] = EMPTY;
      }
    }
  }
  aplicarSpawnDesIndex(idx);
}

boolean jugadorsAMeta() {
  int fp = int(pare.y / TILE_SIZE);
  int cp = int(pare.x / TILE_SIZE);
  int ff = int(fill.y / TILE_SIZE);
  int cf = int(fill.x / TILE_SIZE);
  if (fp < 0 || fp >= ROWS || cp < 0 || cp >= COLS) return false;
  if (ff < 0 || ff >= ROWS || cf < 0 || cf >= COLS) return false;
  return grid[fp][cp] == GOAL && grid[ff][cf] == GOAL;
}

void resetCaixes() {
  caixes.clear();
  for (int f = 0; f < ROWS; f++) {
    for (int c = 0; c < COLS; c++) {
      if (grid[f][c] == BOX) {
        caixes.add(new Crate(c*TILE_SIZE + TILE_SIZE/2, f*TILE_SIZE + TILE_SIZE/2, TILE_SIZE * 0.5f));
      }
    }
  }
}

void copiaGrid(int[][] dest, int[][] src) {
  for (int f = 0; f < ROWS; f++) {
    for (int c = 0; c < COLS; c++) {
      dest[f][c] = src[f][c];
    }
  }
}

void instanciaInterruptorsDesDeGrid() {
  interruptorsGrav.clear();
  float rad = TILE_SIZE * 0.22;
  for (int f = 0; f < ROWS; f++) {
    for (int c = 0; c < COLS; c++) {
      if (grid[f][c] == GRAV_FLIP) {
        interruptorsGrav.add(new InterruptorGrav(c * TILE_SIZE + TILE_SIZE / 2, f * TILE_SIZE + TILE_SIZE / 2, rad));
        grid[f][c] = EMPTY;
      }
    }
  }
}

void restauraGridDesMemoria() {
  if (gridMemoriaJoc == null) return;
  copiaGrid(grid, gridMemoriaJoc);
  interruptorsGrav.clear();
}

boolean interruptorsGravPisats() {
  for (InterruptorGrav ig : interruptorsGrav) {
    if (dist(pare.x, pare.y, ig.x, ig.y) < TILE_SIZE * 0.75) return true;
    if (dist(fill.x, fill.y, ig.x, ig.y) < TILE_SIZE * 0.75) return true;
    for (Crate c : caixes) {
      if (dist(c.x, c.y, ig.x, ig.y) < TILE_SIZE * 0.75) return true;
    }
  }
  return false;
}

void dibuixarNivell(boolean pA, boolean pB, boolean pC) {
  for (int f = 0; f < ROWS; f++) {
    for (int c = 0; c < COLS; c++) {
      float x = c * TILE_SIZE;
      float y = f * TILE_SIZE;
      int t = grid[f][c];
      noStroke();
      switch(t) {
        case WALL:
          if (imgArbust != null) image(imgArbust, x, y, TILE_SIZE + 0.5, TILE_SIZE + 0.5);
          else { fill(60); rect(x, y, TILE_SIZE, TILE_SIZE); }
          break;
        case GAP:
          fill(70);
          rect(x, y, TILE_SIZE, TILE_SIZE/2);
          break;
        case GOAL:
          fill(0, 255, 0, 70);
          rect(x, y, TILE_SIZE, TILE_SIZE);
          break;
        case PLATE_A:
          fill(pA ? #FF4444 : #880000);
          rect(x+TILE_SIZE*0.2, y+TILE_SIZE*0.7, TILE_SIZE*0.6, TILE_SIZE*0.2, 4);
          break;
        case PLATE_B:
          fill(pB ? #4444FF : #000088);
          rect(x+TILE_SIZE*0.2, y+TILE_SIZE*0.7, TILE_SIZE*0.6, TILE_SIZE*0.2, 4);
          break;
        case PLATE_C:
          fill(pC ? #FFFF44 : #B4A818);
          rect(x+TILE_SIZE*0.2, y+TILE_SIZE*0.7, TILE_SIZE*0.6, TILE_SIZE*0.2, 4);
          break;
        case DOOR_A:
          if (!pA) {
            fill(#880000, 200);
            rect(x, y, TILE_SIZE, TILE_SIZE);
            stroke(#FF4444);
            rect(x+2, y+2, TILE_SIZE-4, TILE_SIZE-4);
          }
          break;
        case DOOR_B:
          if (!pB) {
            fill(#000088, 200);
            rect(x, y, TILE_SIZE, TILE_SIZE);
            stroke(#4444FF);
            rect(x+2, y+2, TILE_SIZE-4, TILE_SIZE-4);
          }
          break;
        case DOOR_C:
          if (!pC) {
            fill(#888800, 200);
            rect(x, y, TILE_SIZE, TILE_SIZE);
            stroke(#FFFF44);
            rect(x+2, y+2, TILE_SIZE-4, TILE_SIZE-4);
          }
          break;
        case GRAV_FLIP:
          if (isEditor) {
            float cx = x + TILE_SIZE * 0.5f;
            float H = 14;
            float cy = y + TILE_SIZE - 1 - H * 0.5f;
            float W = TILE_SIZE * 0.58f;
            float Wb = TILE_SIZE * 0.60f;
            float Wt = Wb * 0.88f;
            float yTerra = y + TILE_SIZE - 0.5f;
            float yUnio = cy + H * 0.19f;
            float totalH = max(6.0f, yTerra - yUnio);
            float h1 = totalH * 0.60f;
            float h2 = totalH - h1;
            float yJ = yTerra - h1;
            noStroke();
            fill(32, 48, 60);
            rect(cx - Wb * 0.5f, yJ, Wb, h1);
            rect(cx - Wt * 0.5f, yUnio, Wt, h2);
            noFill();
            stroke(55, 95, 115);
            strokeWeight(1.8f);
            beginShape();
            vertex(cx - Wb * 0.5f, yTerra);
            vertex(cx + Wb * 0.5f, yTerra);
            vertex(cx + Wb * 0.5f, yJ);
            vertex(cx + Wt * 0.5f, yJ);
            vertex(cx + Wt * 0.5f, yUnio);
            vertex(cx - Wt * 0.5f, yUnio);
            vertex(cx - Wt * 0.5f, yJ);
            vertex(cx - Wb * 0.5f, yJ);
            endShape(CLOSE);
            noStroke();
            fill(18, 32, 42, 210);
            ellipse(cx, cy + 1.2f, W + 5, H * 0.36f + 2);
            fill(38, 58, 74);
            ellipse(cx, cy, W + 3, H * 0.34f);
            noFill();
            stroke(45, 175, 230, 200);
            strokeWeight(2);
            ellipse(cx, cy, W, H * 0.30f);
            noStroke();
            fill(52, 78, 98);
            ellipse(cx, cy, W - 4, H * 0.26f);
            fill(28, 48, 62);
            ellipse(cx, cy - 0.8f, W * 0.52f, H * 0.16f);
            for (int k = 0; k < 8; k++) {
              float ang = TWO_PI * k / 8 + frameCount * 0.018f;
              fill(110, 230, 255, 185);
              circle(cx + cos(ang) * (W * 0.36f), cy + sin(ang) * (H * 0.10f), 2.2f);
            }
            float puls = 0.55f + 0.45f * (0.5f + 0.5f * sin(frameCount * 0.08f));
            fill(70, 200, 255, (int)(38 * puls));
            triangle(cx - W * 0.15f, cy - H * 0.12f, cx + W * 0.15f, cy - H * 0.12f, cx, cy - H * 0.12f - 16 * puls);
          }
          break;
        case TRAMPOLINE:
          dibuixaTrampoli(x, y, f, c);
          break;
        case BOX:
          if (isEditor) {
            fill(#8B5A2B);
            stroke(#5C3A21);
            rect(x+4, y+4, TILE_SIZE-8, TILE_SIZE-8, 4);
          }
          break;
      }
    }
  }
}

boolean rectIntersect(float x1, float y1, float w1, float h1, float x2, float y2, float w2, float h2) {
  return x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2;
}

boolean estaPisada(int tipus) {
  for (int f = 0; f < ROWS; f++) {
    for (int c = 0; c < COLS; c++) {
      if (grid[f][c] == tipus) {
        float cx = c * TILE_SIZE + TILE_SIZE / 2;
        float cy = f * TILE_SIZE + TILE_SIZE / 2;
        if (dist(pare.x, pare.y, cx, cy) < TILE_SIZE*0.75) return true;
        if (dist(fill.x, fill.y, cx, cy) < TILE_SIZE*0.75) return true;
        for (Crate caixa : caixes) {
          if (dist(caixa.x, caixa.y, cx, cy) < TILE_SIZE * 0.75) return true;
        }
      }
    }
  }
  return false;
}

// --- Suport segons gravetat (1 = avall, -1 = amunt) ---
boolean solapamentHoritzEntre(float x, float r, float sx, float sr) {
  return abs(x - sx) < (r + sr - 2);
}

boolean contacteSuportPerGravetat(float x, float y, float r, float vy, float sx, float sy, float sr) {
  if (!solapamentHoritzEntre(x, r, sx, sr)) return false;
  if (dirGravetat == 1) {
    return y + r <= sy - sr + 5 && y + r + vy >= sy - sr;
  }
  return y - r >= sy + sr - 5 && y - r + vy <= sy + sr;
}

float yCentratSobreSuport(float sy, float sr, float r) {
  return dirGravetat == 1 ? sy - sr - r : sy + sr + r;
}

boolean velocitatTocaBloc(float vy) {
  return dirGravetat * vy > 0;
}

void actualitzaAnimacioTrampolins() {
  if (trampoliAnim == null) return;
  for (int f = 0; f < ROWS; f++) {
    for (int c = 0; c < COLS; c++) {
      trampoliAnim[f][c] *= 0.82f;
      if (trampoliAnim[f][c] < 0.01f) trampoliAnim[f][c] = 0;
    }
  }
}

void activaAnimacioTrampoli(float px, float py) {
  if (trampoliAnim == null) return;
  int c = floor(px / TILE_SIZE);
  int f = floor(py / TILE_SIZE);
  if (f < 0 || f >= ROWS || c < 0 || c >= COLS) return;
  if (grid[f][c] == TRAMPOLINE) {
    trampoliAnim[f][c] = 1.0f;
    reprodueixSoTrampoliSiCal();
  }
}

void dibuixaTrampoli(float x, float y, int f, int c) {
  float anim = 0;
  if (trampoliAnim != null) anim = trampoliAnim[f][c];
  float cx = x + TILE_SIZE * 0.5f;
  float yTerra = y + TILE_SIZE - 2;
  float ample = TILE_SIZE * 0.66f;
  float barraAlt = max(4, TILE_SIZE * 0.14f);
  float separacioBase = TILE_SIZE * 0.26f;
  float separacio = separacioBase * (1.0f - 0.45f * anim);
  float yBarraBaix = yTerra - barraAlt;
  float yBarraDalt = yBarraBaix - separacio - barraAlt;
  float xBarra = cx - ample * 0.5f;

  // Línia de suport per evitar sensació de flotació.
  noStroke();
  fill(0, 90);
  rect(x + TILE_SIZE * 0.16f, yTerra + 1, TILE_SIZE * 0.68f, 2);

  // Barra superior i inferior: contorn suau perquè no desentoni amb el mapa.
  stroke(78, 118, 82);
  strokeWeight(1.0f);
  fill(#E10000);
  rect(xBarra, yBarraDalt, ample, barraAlt);
  rect(xBarra, yBarraBaix, ample, barraAlt);

  noStroke();
  fill(#FF4A3E);
  rect(xBarra + 2, yBarraDalt + 2, ample - 4, max(1, barraAlt - 4));
  rect(xBarra + 2, yBarraBaix + 2, ample - 4, max(1, barraAlt - 4));

  // Molles laterals plenes (no línies), més properes al model de referència.
  stroke(78, 118, 82);
  strokeWeight(1.0f);
  float xEsq = cx - ample * 0.14f;
  float xDre = cx + ample * 0.14f;
  float yTop = yBarraDalt + barraAlt;
  float yBot = yBarraBaix;
  // Referència: molla més estreta a dalt/baix i més oberta al mig.
  float xMigE = xEsq - TILE_SIZE * 0.12f;
  float xMigD = xDre + TILE_SIZE * 0.12f;
  float yMig = (yTop + yBot) * 0.5f;

  fill(238);
  beginShape();
  vertex(xEsq - 2, yTop);
  vertex(xEsq + 1, yTop);
  vertex(xMigE + 2, yMig);
  vertex(xEsq + 1, yBot);
  vertex(xEsq - 2, yBot);
  vertex(xMigE - 2, yMig);
  endShape(CLOSE);

  beginShape();
  vertex(xDre + 2, yTop);
  vertex(xDre - 1, yTop);
  vertex(xMigD - 2, yMig);
  vertex(xDre - 1, yBot);
  vertex(xDre + 2, yBot);
  vertex(xMigD + 2, yMig);
  endShape(CLOSE);

  noStroke();
  fill(#E10000);
  float capW = max(3.5f, TILE_SIZE * 0.092f);
  float capH = max(3.5f, TILE_SIZE * 0.108f);
  float xCapE = lerp(xEsq, xMigE, 0.95f);
  float xCapD = lerp(xDre, xMigD, 0.95f);
  rect(xCapE - capW * 0.5f, yMig - capH * 0.5f, capW, capH);
  rect(xCapD - capW * 0.5f, yMig - capH * 0.5f, capW, capH);
}
