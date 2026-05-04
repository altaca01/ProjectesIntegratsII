/**
 * EL VINCLE: EXPEDICIÓ - VERSIÓ INTEGRAL
 * - Sincronització de salt i mecàniques completes.
 * - Portes i plaques A, B i C totalment funcionals.
 * - Caixes apilables i moviment en grup.
 * - Accionador de gravetat: 'V' (commuta la gravetat en trepitjar-lo).
 * - Trampolins: 'T' (impuls vertical).
 */

import processing.sound.*;

// --- RECURSOS GRÀFICS ---
PImage imgArbust;
/** Fons pixel art al joc (data/fons.png o fons.jpg); només es dibuixa a l’àrea jugable i fora de l’editor. */
PImage imgFonsJoc;
/** Gràfic de la caixa (data/caja.png o caja.jpg); només visual, mateixa mida que 2*r. */
PImage imgCaja;

// --- ÀUDIO (fitxers dins data/musica/ i data/SFX/) ---
/** Volum (0 = silenci, 1 = màxim). Es reaplica cada frame (veure mantenirVolumMusica). */
float ampMusicaFons = 0.25f;
float ampSaltPare = 0.75f;
float ampGravV1 = 1.0f;
float ampTrampoli = 0.8f;
float ampBoto = 0.35f;
/** Velocitat boto.wav (1 = normal, 3 = tres vegades més ràpid). */
float rateSoBoto = 2.5f;
/** rate > 1 = to més agut: en tornar de gravetat invertida a natural (dir 1). En invertir, rate 1.0. */
float rateSoGravTornANatural = 1.5f;
/** Música nivell 1: amb gravetat invertida (dir != 1), rate < 1 = to més greu; amb dir 1, normal. */
float rateMusicaGravInvertida = 0.85f;
/** Reverb només amb grav invertida (processing.sound.Reverb): room, damp, wet ~0..1 (més wet = més “eco”). */
float reverbMusicaRoom = 0.2f;
float reverbMusicaDamp = 1f;
float reverbMusicaWet = 0.5f;
SoundFile musicaFonsNivell1;
Reverb reverbMusicaGravInvertida;
SoundFile soSaltPare;
SoundFile soSaltNen;
/** Volum SFX salt del fill (fletxa amunt). */
float ampSaltNen = 1f;
SoundFile soGravV1;
SoundFile soTrampoli;
SoundFile soBoto;
SoundFile soVictoria;
float ampVictoria = 1f;
SoundFile soMovCaja;
/** Volum SFX moviment caixa (pare empenta). */
float ampMovCaja = 0.75f;
int darrerFrameSoMovCaja = -100000;
SoundFile soCaminarPare;
SoundFile soCaminarFill;
float ampCaminarPare = 2f;
float ampCaminarFill = 2f;
/** Pitch caminar.wav: pare més greu, fill més agut. */
float rateSoCaminarPare = 1f;
float rateSoCaminarFill = 3f;
int darrerFrameSoCaminarPare = -100000;
int darrerFrameSoCaminarFill = -100000;
/** Mínim de frames entre passos (evita spam). */
int pausaMinCaminarFrames = 16;
/** Flanc plaques A (vermella), B (blava) i C (groga); es comparen després dels update(). */
boolean abansPisPlacaA = false;
boolean abansPisPlacaB = false;
boolean abansPisPlacaC = false;
/** Salts del pare en ràfega curta (frames): puja lleugerament el to amb rate(). */
int rafegaSaltsPare = 0;
int darrerFrameSaltPare = -100000;
/** Trampolí: ràfega curta com el salt del pare (rate més alt). */
int rafegaTrampoli = 0;
int darrerFrameTrampoli = -100000;

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
/** Ambdós jugadors a la meta: SFX victòria, sense moviment fins ESPAI (següent nivell). */
boolean victoriaActiva = false;
/** Evita cridar rate() cada frame; es torna a aplicar quan canvia la gravetat. */
float rateMusicaFonsUltimAplicat = -999f;

void settings() {
  fullScreen();
  pixelDensity(1);
}

void setup() {
  TILE_SIZE = (float)width / COLS;
  ROWS = floor(((float)height / 2.0) / TILE_SIZE);
  grid = new int[ROWS][COLS];
  imgArbust = loadImage("Arbust_002.png");
  imgFonsJoc = loadImage("fons.png");
  if (imgFonsJoc == null || imgFonsJoc.width < 1) {
    imgFonsJoc = loadImage("fons.jpg");
  }
  // Un sol resize a la mida del joc: image() escalant cada frame amb PNG gros va molt lent.
  if (imatgeFonsJocCarregada()) {
    int altFons = max(1, (int) (ROWS * TILE_SIZE));
    imgFonsJoc.resize(width, altFons);
  }

  imgCaja = loadImage("caja.png");
  if (imgCaja == null || imgCaja.width < 1) {
    imgCaja = loadImage("caja.jpg");
  }
  if (imgCaja != null && imgCaja.width > 0) {
    int midaCajaPx = max(1, (int) TILE_SIZE);
    imgCaja.resize(midaCajaPx, midaCajaPx);
  }

  // Música: loop(rate, amp) i després amp() — la Sound de Processing torna a posar guany ~1 dins loop().
  musicaFonsNivell1 = new SoundFile(this, "musica/nivel1.wav");
  musicaFonsNivell1.loop(1.0f, ampMusicaFons);
  mantenirVolumMusica();
  reverbMusicaGravInvertida = new Reverb(this);

  soSaltPare = new SoundFile(this, "SFX/salt_pare.wav");
  soSaltNen = new SoundFile(this, "SFX/salt_nen.wav");
  soGravV1 = new SoundFile(this, "SFX/grav_v1.wav");
  soTrampoli = new SoundFile(this, "SFX/trampoli.wav");
  soBoto = new SoundFile(this, "SFX/boto.wav");
  soVictoria = new SoundFile(this, "SFX/victoria.wav");
  soMovCaja = new SoundFile(this, "SFX/mov_caja.wav");
  soCaminarPare = new SoundFile(this, "SFX/caminar.wav");
  soCaminarFill = new SoundFile(this, "SFX/caminar.wav");

  indexNivellActual = 0;
  gridMemoriaJoc = new int[ROWS][COLS];
  trampoliAnim = new float[ROWS][COLS];
  pare = new Player(TILE_SIZE*1.5, TILE_SIZE*1.5, TILE_SIZE*0.4, #8B0000, false);
  fill = new Player(TILE_SIZE*4.5, TILE_SIZE*1.5, TILE_SIZE*0.25, #E2B13C, true);
  carregarNivellDesIndex(indexNivellActual);
  resetCaixes();
}

/** Salt del pare amb W: SFX; el to puja una mica si salta diverses vegades seguides (rate). */
void reprodueixSoSaltPareSiCal() {
  if (isEditor || soSaltPare == null) return;
  int dt = frameCount - darrerFrameSaltPare;
  if (dt < 28) {
    rafegaSaltsPare = min(rafegaSaltsPare + 1, 8);
  } else {
    rafegaSaltsPare = 0;
  }
  darrerFrameSaltPare = frameCount;
  float elevacioTo = min(0.18f, rafegaSaltsPare * 0.028f);
  float r = 1.0f + elevacioTo;
  soSaltPare.play(r, ampSaltPare);
  soSaltPare.amp(ampSaltPare);
}

void reprodueixSoSaltNenSiCal() {
  if (isEditor || soSaltNen == null) return;
  soSaltNen.play(1.0f, ampSaltNen);
  soSaltNen.amp(ampSaltNen);
}

void reprodueixSoTrampoliSiCal() {
  if (isEditor || soTrampoli == null) return;
  int dt = frameCount - darrerFrameTrampoli;
  if (dt < 28) {
    rafegaTrampoli = min(rafegaTrampoli + 1, 8);
  } else {
    rafegaTrampoli = 0;
  }
  darrerFrameTrampoli = frameCount;
  float elevacioTo = min(0.18f, rafegaTrampoli * 0.028f);
  float r = 1.0f + elevacioTo;
  soTrampoli.play(r, ampTrampoli);
  soTrampoli.amp(ampTrampoli);
}

void reprodueixSoBotoPlacaSiCal() {
  if (isEditor || soBoto == null) return;
  if (soBoto.isPlaying()) soBoto.stop();
  soBoto.amp(ampBoto);
  soBoto.play(rateSoBoto, ampBoto);
  soBoto.amp(ampBoto);
}

/** Pare empenta una caixa lateralment (dx real aplicat a la caixa). Mateix ritme que caminar (pausaMinCaminarFrames). */
void notificaSoMovCajaPerEmpentaPare(float dxEmpenta) {
  if (isEditor || soMovCaja == null) return;
  if (abs(dxEmpenta) < 0.02f) return;
  if (frameCount - darrerFrameSoMovCaja < pausaMinCaminarFrames) return;
  darrerFrameSoMovCaja = frameCount;
  // Sense stop(), diversos play() solapats sumen volum; el motor també pot reaplicar guany alt a cada play().
  if (soMovCaja.isPlaying()) soMovCaja.stop();
  soMovCaja.amp(ampMovCaja);
  soMovCaja.play(1.0f, ampMovCaja);
  soMovCaja.amp(ampMovCaja);
}

void reprodueixSoCaminarPareSiCal() {
  if (isEditor || soCaminarPare == null) return;
  if (frameCount - darrerFrameSoCaminarPare < pausaMinCaminarFrames) return;
  darrerFrameSoCaminarPare = frameCount;
  soCaminarPare.play(rateSoCaminarPare, ampCaminarPare);
  soCaminarPare.amp(ampCaminarPare);
}

void reprodueixSoCaminarFillSiCal() {
  if (isEditor || soCaminarFill == null) return;
  if (frameCount - darrerFrameSoCaminarFill < pausaMinCaminarFrames) return;
  darrerFrameSoCaminarFill = frameCount;
  soCaminarFill.play(rateSoCaminarFill, ampCaminarFill);
  soCaminarFill.amp(ampCaminarFill);
}

void reprodueixSoGravV1SiCal(boolean gravetatNaturalAbansDelCanvi) {
  if (isEditor || soGravV1 == null) return;
  float r = gravetatNaturalAbansDelCanvi ? 1.0f : rateSoGravTornANatural;
  soGravV1.play(r, ampGravV1);
  soGravV1.amp(ampGravV1);
}

void reprodueixSoVictoriaSiCal() {
  if (isEditor || soVictoria == null) return;
  if (soVictoria.isPlaying()) soVictoria.stop();
  soVictoria.amp(ampVictoria);
  soVictoria.play(1.0f, ampVictoria);
  soVictoria.amp(ampVictoria);
}

boolean gravetatBloquejadaPerSoGrav() {
  return !isEditor && soGravV1 != null && soGravV1.isPlaying();
}

/** Bug Processing Sound: després d’arrencar play/loop el motor reaplica amp intern 1; cal amp() de nou (i cada frame per la música). */
void mantenirVolumMusica() {
  if (musicaFonsNivell1 != null) musicaFonsNivell1.amp(ampMusicaFons);
}

void actualitzaRateMusicaSegonsGravetat() {
  if (musicaFonsNivell1 == null) return;
  float r = (dirGravetat == 1) ? 1.0f : rateMusicaGravInvertida;
  if (r == rateMusicaFonsUltimAplicat) return;
  rateMusicaFonsUltimAplicat = r;
  musicaFonsNivell1.rate(r);
  mantenirVolumMusica();
}

void paraEfecteReverbMusicaSiCal() {
  if (reverbMusicaGravInvertida != null && reverbMusicaGravInvertida.isProcessing()) {
    reverbMusicaGravInvertida.stop();
  }
}

/** Amb grav invertida: reverb (eco/espai). Només un Effect per SoundFile a la llibreria Sound. */
void actualitzaEfecteMusicaSegonsGravetat() {
  if (musicaFonsNivell1 == null || reverbMusicaGravInvertida == null) return;
  if (dirGravetat != 1) {
    if (!reverbMusicaGravInvertida.isProcessing()) {
      reverbMusicaGravInvertida.set(reverbMusicaRoom, reverbMusicaDamp, reverbMusicaWet);
      reverbMusicaGravInvertida.process(musicaFonsNivell1);
      mantenirVolumMusica();
    }
  } else {
    paraEfecteReverbMusicaSiCal();
  }
}

void draw() {
  background(10);
  mantenirVolumMusica();
  actualitzaRateMusicaSegonsGravetat();
  actualitzaEfecteMusicaSegonsGravetat();
  if (!isEditor && imatgeFonsJocCarregada()) {
    dibuixaFonsImatgeJoc();
  } else {
    dibuixaCelDegradat();
    dibuixaDecoracioFons();
  }

  boolean pA = estaPisada(PLATE_A);
  boolean pB = estaPisada(PLATE_B);
  boolean pC = estaPisada(PLATE_C);

  boolean pisantGrav = isEditor ? estaPisada(GRAV_FLIP) : interruptorsGravPisats();
  if (pisantGrav) {
    if (!gravPadPisat && !gravetatBloquejadaPerSoGrav()) {
      boolean gravNatural = (dirGravetat == 1);
      dirGravetat = -dirGravetat;
      gravPadPisat = true;
      reprodueixSoGravV1SiCal(gravNatural);
    }
  } else {
    gravPadPisat = false;
  }

  actualitzaAnimacioTrampolins();
  dibuixarNivell(pA, pB, pC);

  if (!isEditor) {
    if (!victoriaActiva) {
      for (InterruptorGrav ig : interruptorsGrav) ig.update(pA, pB, pC);
      for (Crate c : caixes) c.update(pA, pB, pC);
      pare.update(pA, pB, pC, null);
      fill.update(pA, pB, pC, pare);
      if (jugadorsAMeta()) {
        victoriaActiva = true;
        reprodueixSoVictoriaSiCal();
        pare.vx = pare.vy = 0;
        fill.vx = fill.vy = 0;
        for (int i = 0; i < 256; i++) {
          keys[i] = false;
          keysCode[i] = false;
        }
      }
    } else {
      pare.vx = pare.vy = 0;
      fill.vx = fill.vy = 0;
    }
    verificarVictoria();
    boolean pAFi = estaPisada(PLATE_A);
    boolean pBFi = estaPisada(PLATE_B);
    boolean pCFi = estaPisada(PLATE_C);
    if (pAFi && !abansPisPlacaA) reprodueixSoBotoPlacaSiCal();
    if (pBFi && !abansPisPlacaB) reprodueixSoBotoPlacaSiCal();
    if (pCFi && !abansPisPlacaC) reprodueixSoBotoPlacaSiCal();
    abansPisPlacaA = pAFi;
    abansPisPlacaB = pBFi;
    abansPisPlacaC = pCFi;
  } else {
    abansPisPlacaA = estaPisada(PLATE_A);
    abansPisPlacaB = estaPisada(PLATE_B);
    abansPisPlacaC = estaPisada(PLATE_C);
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
    String sNiv = "Nivell " + (indexNivellActual + 1) + " / " + NIVELLS.length;
    dibuixaTextAmbContorn(sNiv, width - 18, 18, RIGHT, TOP, 30, color(255, 252, 248), color(0, 0, 0), 5.2f);
  }
}

/**
 * Contorn gruixut segur: el text() amb stroke a Processing sovint no es veu;
 * es dibuixa el mateix text moltes vegades amb fill fosc desplaçat i després el fill clar al centre.
 */
void dibuixaTextAmbContorn(String txt, float x, float y, int ha, int va, float mida, color f, color st, float sw) {
  pushStyle();
  textAlign(ha, va);
  textSize(mida);
  textLeading(mida * 1.15f);
  noStroke();
  color contorn = lerpColor(st, color(0, 0, 0), 0.96f);
  fill(contorn);

  float[] radii = { max(3.5f, sw * 1.1f), max(2.4f, sw * 0.72f), max(1.4f, sw * 0.38f) };
  int[] counts = { 22, 16, 12 };
  for (int p = 0; p < radii.length; p++) {
    float rad = radii[p];
    int nn = counts[p];
    for (int i = 0; i < nn; i++) {
      float ang = TWO_PI * i / nn;
      text(txt, x + cos(ang) * rad, y + sin(ang) * rad);
    }
  }
  float d = max(2.8f, sw * 0.88f);
  text(txt, x - d, y);
  text(txt, x + d, y);
  text(txt, x, y - d);
  text(txt, x, y + d);
  text(txt, x - d * 0.72f, y - d * 0.72f);
  text(txt, x + d * 0.72f, y - d * 0.72f);
  text(txt, x - d * 0.72f, y + d * 0.72f);
  text(txt, x + d * 0.72f, y + d * 0.72f);

  fill(f);
  text(txt, x, y);
  popStyle();
}

boolean imatgeFonsJocCarregada() {
  return imgFonsJoc != null && imgFonsJoc.width > 0;
}

/** Fons d’imatge només a la meitat superior jugable (ja redimensionada al setup). */
void dibuixaFonsImatgeJoc() {
  if (!imatgeFonsJocCarregada()) return;
  imageMode(CORNER);
  image(imgFonsJoc, 0, 0);
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

/** Després de carregar el grid d'un nivell: interruptors, caixes, gravetat i teclat. */
void aplicarFisicaInicialDespresCarregarNivell() {
  victoriaActiva = false;
  dirGravetat = 1;
  gravPadPisat = false;
  rateMusicaFonsUltimAplicat = -999f;
  paraEfecteReverbMusicaSiCal();
  if (soGravV1 != null && soGravV1.isPlaying()) soGravV1.stop();
  interruptorsGrav.clear();
  instanciaInterruptorsDesDeGrid();
  resetCaixes();
  reiniciaTrampolinsAnim();
  for (int i = 0; i < 256; i++) {
    keys[i] = false;
    keysCode[i] = false;
  }
  aplicarSpawnDesIndex(indexNivellActual);
  abansPisPlacaA = estaPisada(PLATE_A);
  abansPisPlacaB = estaPisada(PLATE_B);
  abansPisPlacaC = estaPisada(PLATE_C);
}

/** Torna a començar el nivell actual (mateix índex), no el primer nivell. */
void reiniciaNivellActual() {
  if (isEditor || NIVELLS == null) return;
  carregarNivellDesIndex(indexNivellActual);
  aplicarFisicaInicialDespresCarregarNivell();
}

void passarSeguentNivell() {
  if (NIVELLS == null || indexNivellActual >= NIVELLS.length - 1) return;
  indexNivellActual++;
  carregarNivellDesIndex(indexNivellActual);
  aplicarFisicaInicialDespresCarregarNivell();
}
