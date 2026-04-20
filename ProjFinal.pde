/**
 * EL VINCLE: EXPEDICIÓ - VERSIÓ INTEGRAL
 * - Sincronització de salt i mecàniques completes.
 * - Portes i plaques A, B i C totalment funcionals.
 * - Caixes apilables i moviment en grup.
 * - Accionador de gravetat: 'V' (commuta la gravetat en trepitjar-lo).
 * - Trampolins: 'T' (impuls vertical).
 */

// --- RECURSOS GRÀFICS ---
PImage imgArbust;

// --- CONFIGURACIÓ DE REIXETA ---
float TILE_SIZE;
int COLS = 35;
int ROWS;
int[][] grid;

// --- ESTAT DEL JOC ---
boolean isEditor = true;
boolean mostrarGuia = true;
int selected = 1;
boolean gravPadPisat = false;

// --- FÍSIQUES ---
float gravetatForca = 0.5;
int dirGravetat = 1;
float friccio = 0.85;

// --- IDENTIFICADORS ---
final int EMPTY=0, WALL=1, GAP=2, GOAL=3;
final int PLATE_A=4, PLATE_B=5, PLATE_C=6;
final int DOOR_A=7, DOOR_B=8, DOOR_C=9;
final int BOX=10;
final int GRAV_FLIP = 11, TRAMPOLINE = 13;

Player pare, fill;
ArrayList<Crate> caixes = new ArrayList<Crate>();
ArrayList<InterruptorGrav> interruptorsGrav = new ArrayList<InterruptorGrav>();
int[][] gridMemoriaJoc;
boolean[] keys = new boolean[256];
boolean[] keysCode = new boolean[256];
float[][] trampoliAnim;

/** Índex del nivell actiu (0 = primer, 1 = segon, …). Les dades dels mapes són a Nivells.pde (NIVELLS). */
int indexNivellActual = 0;

void settings() {
  fullScreen();
  pixelDensity(1);
}

void setup() {
  TILE_SIZE = (float)width / COLS;
  ROWS = floor(((float)height / 2.0) / TILE_SIZE);
  grid = new int[ROWS][COLS];
  imgArbust = loadImage("Arbust_002.png");
  indexNivellActual = 0;
  gridMemoriaJoc = new int[ROWS][COLS];
  trampoliAnim = new float[ROWS][COLS];
  pare = new Player(TILE_SIZE*1.5, TILE_SIZE*1.5, TILE_SIZE*0.4, #8B0000, false);
  fill = new Player(TILE_SIZE*4.5, TILE_SIZE*1.5, TILE_SIZE*0.25, #E2B13C, true);
  carregarNivellDesIndex(indexNivellActual);
  resetCaixes();
}

void draw() {
  background(10);
  dibuixaCelDegradat();
  dibuixaDecoracioFons();

  boolean pA = estaPisada(PLATE_A);
  boolean pB = estaPisada(PLATE_B);
  boolean pC = estaPisada(PLATE_C);

  boolean pisantGrav = isEditor ? estaPisada(GRAV_FLIP) : interruptorsGravPisats();
  if (pisantGrav) {
    if (!gravPadPisat) {
      dirGravetat = -dirGravetat;
      gravPadPisat = true;
    }
  } else {
    gravPadPisat = false;
  }

  actualitzaAnimacioTrampolins();
  dibuixarNivell(pA, pB, pC);

  if (!isEditor) {
    for (InterruptorGrav ig : interruptorsGrav) ig.update(pA, pB, pC);
    for (Crate c : caixes) c.update(pA, pB, pC);
    pare.update(pA, pB, pC, null);
    fill.update(pA, pB, pC, pare);
    verificarVictoria();
  }

  if (!isEditor) {
    for (Crate c : caixes) c.display();
    for (InterruptorGrav ig : interruptorsGrav) ig.display();
  }
  pare.display();
  fill.display();

  if (isEditor) {
    dibuixarIndicadorEditor();
    if (mostrarGuia) dibuixarGuiaEditor();
  } else if (NIVELLS != null) {
    fill(255);
    textAlign(RIGHT, TOP);
    textSize(16);
    text("Nivell " + (indexNivellActual + 1) + " / " + NIVELLS.length, width - 16, 12);
  }
}

/** Cel degradat dins l'àrea de joc (amplada = finestra, alçada = ROWS * TILE_SIZE). */
void dibuixaCelDegradat() {
  float h = ROWS * TILE_SIZE;
  int passes = max(12, (int) (h / 3));
  noStroke();
  for (int i = 0; i < passes; i++) {
    float t = passes <= 1 ? 0 : (float) i / (passes - 1);
    color top = color(120, 185, 230);
    color bot = color(200, 230, 210);
    fill(lerpColor(top, bot, t));
    float y0 = (h * i) / passes;
    float y1 = (h * (i + 1)) / passes;
    rect(0, y0, width, y1 - y0 + 0.5f);
  }
}

/** Núvols, muntanyes i arbres darrere el nivell (estil pixel simple, coherent amb el mapa). */
void dibuixaDecoracioFons() {
  float h = ROWS * TILE_SIZE;
  dibuixaNuvolsFons(h);
  dibuixaMuntanyaLlunyana(h);
  dibuixaMuntanyaPropera(h);
  dibuixaArbresFons(h);
}

void dibuixaNuvol(float cx, float cy, float mida) {
  noStroke();
  fill(255, 252, 255, 210);
  ellipse(cx - mida * 0.35f, cy, mida * 0.42f, mida * 0.26f);
  fill(255, 255, 255, 200);
  ellipse(cx, cy, mida * 0.52f, mida * 0.32f);
  fill(245, 248, 252, 195);
  ellipse(cx + mida * 0.38f, cy, mida * 0.4f, mida * 0.24f);
}

void dibuixaNuvolsFons(float h) {
  float m = TILE_SIZE * 1.15f;
  float drift = sin(frameCount * 0.008f) * TILE_SIZE * 0.15f;
  float dy = TILE_SIZE;

  dibuixaNuvol(width * 0.18f + drift, h * 0.12f + dy, m * 1.1f);
  dibuixaNuvol(width * 0.48f - drift * 0.7f, h * 0.08f + dy, m * 0.95f);
  dibuixaNuvol(width * 0.78f + drift * 0.5f, h * 0.15f + dy, m);
  dibuixaNuvol(width * 0.92f - drift, h * 0.22f + dy, m * 0.75f);
  dibuixaNuvol(width * 0.05f + drift * 0.4f, h * 0.28f + dy, m * 0.65f);
  dibuixaNuvol(width * 0.33f + drift * 0.3f, h * 0.06f + dy, m * 0.85f);
  dibuixaNuvol(width * 0.62f - drift * 0.45f, h * 0.18f + dy, m * 0.9f);
  dibuixaNuvol(width * 0.85f + drift * 0.25f, h * 0.1f + dy, m * 0.7f);
  dibuixaNuvol(width * 0.12f - drift * 0.35f, h * 0.2f + dy, m * 0.72f);
}

/** Cresta de la muntanya propera (mateix polígon que dibuixaMuntanyaPropera), per apoyar arbres. */
float crestaMuntanyaPropera(float x, float h) {
  float base = h * 0.96f;
  float[] vx = {
    0, width * 0.1f, width * 0.25f, width * 0.4f, width * 0.55f, width * 0.7f, width * 0.85f, width
  };
  float[] vy = {
    base - h * 0.06f, base - h * 0.16f, base - h * 0.05f, base - h * 0.2f,
    base - h * 0.07f, base - h * 0.18f, base - h * 0.04f, base - h * 0.14f
  };
  x = constrain(x, 0, width);
  if (x <= vx[0]) return vy[0];
  if (x >= vx[vx.length - 1]) return vy[vx.length - 1];
  for (int i = 0; i < vx.length - 1; i++) {
    if (x >= vx[i] && x <= vx[i + 1]) {
      float t = (x - vx[i]) / (vx[i + 1] - vx[i]);
      return lerp(vy[i], vy[i + 1], t);
    }
  }
  return vy[0];
}

void dibuixaMuntanyaLlunyana(float h) {
  noStroke();
  float base = h * 0.94f;
  fill(78, 108, 128);
  beginShape();
  vertex(0, h);
  vertex(0, base - h * 0.2f);
  vertex(width * 0.12f, base - h * 0.32f);
  vertex(width * 0.28f, base - h * 0.14f);
  vertex(width * 0.42f, base - h * 0.36f);
  vertex(width * 0.58f, base - h * 0.18f);
  vertex(width * 0.72f, base - h * 0.3f);
  vertex(width * 0.88f, base - h * 0.12f);
  vertex(width, base - h * 0.22f);
  vertex(width, h);
  endShape(CLOSE);
}

void dibuixaMuntanyaPropera(float h) {
  noStroke();
  float base = h * 0.96f;
  fill(62, 92, 72);
  beginShape();
  vertex(0, h);
  vertex(0, base - h * 0.06f);
  vertex(width * 0.1f, base - h * 0.16f);
  vertex(width * 0.25f, base - h * 0.05f);
  vertex(width * 0.4f, base - h * 0.2f);
  vertex(width * 0.55f, base - h * 0.07f);
  vertex(width * 0.7f, base - h * 0.18f);
  vertex(width * 0.85f, base - h * 0.04f);
  vertex(width, base - h * 0.14f);
  vertex(width, h);
  endShape(CLOSE);
}

void dibuixaArbre(float x, float baseY, float escala) {
  stroke(52, 78, 56);
  strokeWeight(1);
  fill(48, 92, 54);
  triangle(x, baseY - escala * 1.1f, x - escala * 0.55f, baseY, x + escala * 0.55f, baseY);
  fill(40, 82, 48);
  triangle(x, baseY - escala * 1.45f, x - escala * 0.42f, baseY - escala * 0.35f, x + escala * 0.42f, baseY - escala * 0.35f);
  noStroke();
  fill(72, 52, 38);
  rect(x - escala * 0.12f, baseY - escala * 0.15f, escala * 0.24f, escala * 0.2f);
}

void dibuixaArbresFons(float h) {
  randomSeed(28471);
  float e0 = TILE_SIZE * 0.5f;
  int n = 14;
  float marge = width * 0.14f;
  float xMin = marge + TILE_SIZE * 0.3f;
  float xMax = width - marge - TILE_SIZE * 0.3f;
  for (int i = 0; i < n; i++) {
    float x = random(xMin, xMax);
    float cresta = crestaMuntanyaPropera(x, h);
    float yDalt = cresta + TILE_SIZE * 0.06f;
    float yBaix = min(cresta + h * 0.22f, h * 0.9f);
    float baseY = (yBaix > yDalt + 2) ? random(yDalt, yBaix) : yDalt;
    dibuixaArbre(x, baseY, e0 * random(0.72f, 0.98f));
  }
}

void reiniciaTrampolinsAnim() {
  if (trampoliAnim == null) return;
  for (int f = 0; f < ROWS; f++) {
    for (int c = 0; c < COLS; c++) {
      trampoliAnim[f][c] = 0;
    }
  }
}

void passarSeguentNivell() {
  if (NIVELLS == null || indexNivellActual >= NIVELLS.length - 1) return;
  indexNivellActual++;
  carregarNivellDesIndex(indexNivellActual);
  dirGravetat = 1;
  gravPadPisat = false;
  interruptorsGrav.clear();
  instanciaInterruptorsDesDeGrid();
  resetCaixes();
  reiniciaTrampolinsAnim();
  for (int i = 0; i < 256; i++) {
    keys[i] = false;
    keysCode[i] = false;
  }
  aplicarSpawnDesIndex(indexNivellActual);
}
