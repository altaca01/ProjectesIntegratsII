/**
 * THE BOND: EXPEDITION - INTEGRAL VERSION (Sincronització de Salt i Mecàniques Completes)
 * - Portes i plaques A, B i C totalment funcionals.
 * - Caixes apilables (Stacking) i moviment en grup.
 * - Botons de gravetat: 'V' (Avall) i 'B' (Amunt).
 * - Trampolins: 'T' (Impuls vertical).
 * - CORRECCIÓ DE SALT: El fill i les caixes hereten la velocitat del suport.
 */

// --- ASSETS ---
PImage imgArbust, imgGrass;

// --- CONFIGURACIÓ DE REIXETA ---
float TILE_SIZE; 
int COLS = 35; 
int ROWS;
int[][] grid;

// --- ESTAT DEL JOC ---
boolean isEditor = true;
boolean mostrarGuia = true; 
int selected = 1;

// --- FÍSIQUES ---
float gravetatForca = 0.5;
int dirGravetat = 1; 
float friccio = 0.85;

// --- IDENTIFICADORS ---
final int EMPTY=0, WALL=1, GAP=2, GOAL=3;
final int PLATE_A=4, PLATE_B=5, PLATE_C=6; 
final int DOOR_A=7, DOOR_B=8, DOOR_C=9;
final int BOX=10;
final int GRAV_DOWN=11, GRAV_UP=12, TRAMPOLINE=13;

Player pare, fill;
ArrayList<Crate> caixes = new ArrayList<Crate>();
boolean[] keys = new boolean[256];
boolean[] keysCode = new boolean[256];

// NIVELL D'EXEMPLE
int[][] NIVEL_CARGADO = {
  {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
  {1,0,0,0,0,0,0,0,0,2,2,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,1},
  {1,1,1,1,1,7,7,1,1,1,1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,10,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,4,1,0,0,1,0,0,0,0,1,8,1,1,1,1,1,1,1,1,1,1},
  {1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,12,1},
  {1,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,0,0,0,0,1,8,1,1,1,1,1,1,1,1,1,1},
  {1,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,3,3,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,13,0,0,0,0,10,0,0,0,5,1},
  {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
};

void settings() { fullScreen(); }

void setup() {
  TILE_SIZE = (float)width / COLS;
  ROWS = floor(((float)height / 2.0) / TILE_SIZE);
  grid = new int[ROWS][COLS];
  imgArbust = loadImage("Arbust_002.png"); 
  imgGrass = loadImage("Grass_001.png"); 
  cargarNivelInteligent();
  pare = new Player(TILE_SIZE*1.5, TILE_SIZE*1.5, TILE_SIZE*0.4, #8B0000, false);
  fill = new Player(TILE_SIZE*4.5, TILE_SIZE*1.5, TILE_SIZE*0.25, #E2B13C, true);
  resetCaixes();
}

void cargarNivelInteligent() {
  if (NIVEL_CARGADO != null) {
    for (int f = 0; f < ROWS; f++) {
      for (int c = 0; c < COLS; c++) {
        if (f < NIVEL_CARGADO.length && c < NIVEL_CARGADO[0].length) grid[f][c] = NIVEL_CARGADO[f][c];
      }
    }
  }
}

void resetCaixes() {
  caixes.clear();
  for(int f=0; f<ROWS; f++) {
    for(int c=0; c<COLS; c++) {
      if(grid[f][c] == BOX) caixes.add(new Crate(c*TILE_SIZE + TILE_SIZE/2, f*TILE_SIZE + TILE_SIZE/2, TILE_SIZE*0.4));
    }
  }
}

void draw() {
  background(10); 
  fill(15); noStroke();
  rect(0, 0, width, ROWS * TILE_SIZE);
  
  boolean pA = estaPisada(PLATE_A);
  boolean pB = estaPisada(PLATE_B);
  boolean pC = estaPisada(PLATE_C);
  
  if (estaPisada(GRAV_DOWN)) dirGravetat = 1;
  if (estaPisada(GRAV_UP)) dirGravetat = -1;
  
  dibujarNivel(pA, pB, pC);
  
  if (!isEditor) {
    for (Crate c : caixes) { c.update(pA, pB, pC); }
    pare.update(pA, pB, pC, null); 
    fill.update(pA, pB, pC, pare);
    verificarVictoria();
  }
  
  for (Crate c : caixes) { c.display(); }
  pare.display();
  fill.display();
  
  if (isEditor) {
    dibujarIndicadorEditor();
    if (mostrarGuia) dibuixarGuiaEditor();
  }
}

void dibujarNivel(boolean pA, boolean pB, boolean pC) {
  for (int f = 0; f < ROWS; f++) {
    for (int c = 0; c < COLS; c++) {
      float x = c * TILE_SIZE; float y = f * TILE_SIZE; int t = grid[f][c];
      if (t != WALL && imgGrass != null) image(imgGrass, x, y, TILE_SIZE + 0.5, TILE_SIZE + 0.5);
      noStroke();
      switch(t) {
        case WALL:
          if (imgArbust != null) image(imgArbust, x, y, TILE_SIZE + 0.5, TILE_SIZE + 0.5);
          else { fill(60); rect(x, y, TILE_SIZE, TILE_SIZE); }
          break;
        case GAP: fill(70); rect(x, y, TILE_SIZE, TILE_SIZE/2); break;
        case GOAL: fill(0, 255, 0, 70); rect(x, y, TILE_SIZE, TILE_SIZE); break;
        case PLATE_A: fill(pA ? #FF4444 : #880000); rect(x+TILE_SIZE*0.2, y+TILE_SIZE*0.7, TILE_SIZE*0.6, TILE_SIZE*0.2, 4); break;
        case PLATE_B: fill(pB ? #4444FF : #000088); rect(x+TILE_SIZE*0.2, y+TILE_SIZE*0.7, TILE_SIZE*0.6, TILE_SIZE*0.2, 4); break;
        case PLATE_C: fill(pC ? #FFFF44 : #888800); rect(x+TILE_SIZE*0.2, y+TILE_SIZE*0.7, TILE_SIZE*0.6, TILE_SIZE*0.2, 4); break;
        case DOOR_A: if (!pA) { fill(#880000, 200); rect(x, y, TILE_SIZE, TILE_SIZE); stroke(#FF4444); rect(x+2,y+2,TILE_SIZE-4,TILE_SIZE-4); } break;
        case DOOR_B: if (!pB) { fill(#000088, 200); rect(x, y, TILE_SIZE, TILE_SIZE); stroke(#4444FF); rect(x+2,y+2,TILE_SIZE-4,TILE_SIZE-4); } break;
        case DOOR_C: if (!pC) { fill(#888800, 200); rect(x, y, TILE_SIZE, TILE_SIZE); stroke(#FFFF44); rect(x+2,y+2,TILE_SIZE-4,TILE_SIZE-4); } break;
        case GRAV_DOWN: fill(150); rect(x+5, y+TILE_SIZE-10, TILE_SIZE-10, 10); fill(0); triangle(x+TILE_SIZE/2, y+TILE_SIZE-2, x+10, y+TILE_SIZE-8, x+TILE_SIZE-10, y+TILE_SIZE-8); break;
        case GRAV_UP: fill(150); rect(x+5, y, TILE_SIZE-10, 10); fill(0); triangle(x+TILE_SIZE/2, y+2, x+10, y+8, x+TILE_SIZE-10, y+8); break;
        case TRAMPOLINE: fill(#FF00FF); rect(x, y+TILE_SIZE-8, TILE_SIZE, 8); fill(255, 150); rect(x+4, y+TILE_SIZE-12, TILE_SIZE-8, 4); break;
        case BOX: if (isEditor) { fill(#8B5A2B); stroke(#5C3A21); rect(x+4, y+4, TILE_SIZE-8, TILE_SIZE-8, 4); } break;
      }
    }
  }
}

boolean rectIntersect(float x1, float y1, float w1, float h1, float x2, float y2, float w2, float h2) {
  return x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2;
}

class Crate {
  float x, y, r, vx, vy;
  boolean aTerra;
  Crate(float _x, float _y, float _r) { x=_x; y=_y; r=_r; }

  void update(boolean pA, boolean pB, boolean pC) {
    vy += gravetatForca * dirGravetat; vx *= friccio;
    if (grid[int(y/TILE_SIZE)][int(x/TILE_SIZE)] == TRAMPOLINE) { vy = -12 * dirGravetat; }

    if(puedo(x + vx, y, pA, pB, pC)) {
      float oldX = x; x += vx;
      for (Crate a : caixes) { if (a != this && a.estaSobre(this)) a.x += (x - oldX); }
    } else vx = 0;

    boolean sobreSuport = false;
    // Sincronització amb Pare
    if (abs(x - pare.x) < (r + pare.r - 2) && (dirGravetat == 1 && y+r <= pare.y-pare.r+5 && y+r+vy >= pare.y-pare.r)) {
      y = pare.y - pare.r - r; vy = pare.vy; sobreSuport = true;
    }
    // Sincronització amb altres caixes
    for (Crate a : caixes) { 
      if (a != this && abs(x - a.x) < (r + a.r - 2) && (dirGravetat == 1 && y+r <= a.y-a.r+5 && y+r+vy >= a.y-a.r)) { 
        y = a.y - a.r - r; vy = a.vy; sobreSuport = true; 
      } 
    }

    if (!sobreSuport) {
      if(puedo(x, y + vy, pA, pB, pC)) { y += vy; aTerra = false; }
      else { aTerra = true; vy = 0; }
    } else { aTerra = true; }
  }

  boolean estaSobre(Crate s) { return abs(x - s.x) < (r + s.r - 2) && abs((y + r) - (s.y - s.r)) < 5; }
  void mourePerSuport(float dx, float dy, boolean pA, boolean pB, boolean pC) { if (puedo(x + dx, y + dy, pA, pB, pC)) { x += dx; y += dy; for (Crate a : caixes) if (a != this && a.estaSobre(this)) a.mourePerSuport(dx, dy, pA, pB, pC); } }

  boolean puedo(float nx, float ny, boolean pA, boolean pB, boolean pC) {
    float m = r * 0.8;
    if (!check(nx-m, ny-m, pA, pB, pC) || !check(nx+m, ny+m, pA, pB, pC)) return false;
    if (rectIntersect(nx-r, ny-r, r*2, r*2, fill.x-fill.r, fill.y-fill.r, fill.r*2, fill.r*2)) return false;
    return true;
  }

  boolean check(float px, float py, boolean pA, boolean pB, boolean pC) {
    int c = floor(px / TILE_SIZE); int f = floor(py / TILE_SIZE);
    if(f < 0 || f >= ROWS || c < 0 || c >= COLS) return false;
    int t = grid[f][c];
    if(t == WALL || (t == DOOR_A && !pA) || (t == DOOR_B && !pB) || (t == DOOR_C && !pC)) return false;
    return true;
  }

  void display() { pushMatrix(); translate(x, y); fill(#8B5A2B); stroke(#5C3A21); strokeWeight(2); rect(-r, -r, r*2, r*2, 4); line(-r, -r, r, r); line(r, -r, -r, r); popMatrix(); }
}

class Player {
  float x, y, r, vx, vy; color col; boolean esFill, aTerra;
  Player(float _x, float _y, float _r, color _c, boolean _h) { x=_x; y=_y; r=_r; col=_c; esFill=_h; }

  void update(boolean pA, boolean pB, boolean pC, Player altre) {
    float ax = 0; float speed = esFill ? TILE_SIZE*0.015 : TILE_SIZE*0.011; float jump = esFill ? TILE_SIZE*0.25 : TILE_SIZE*0.22;
    if(!esFill) { if(keys['a'] || keys['A']) ax -= speed; if(keys['d'] || keys['D']) ax += speed; if((keys['w'] || keys['W']) && aTerra) { vy = -jump * dirGravetat; aTerra = false; } }
    else { if(keysCode[LEFT]) ax -= speed; if(keysCode[RIGHT]) ax += speed; if(keysCode[UP] && aTerra) { vy = -jump * dirGravetat; aTerra = false; } }
    vx = (vx + ax) * friccio; vy += gravetatForca * dirGravetat;
    if (grid[int(y/TILE_SIZE)][int(x/TILE_SIZE)] == TRAMPOLINE) { vy = -15 * dirGravetat; aTerra = false; }
    if(puedo(x + vx, y, pA, pB, pC)) x += vx; else vx = 0;
    
    boolean sobreSuport = false;
    for (Crate c : caixes) { 
      if (abs(x - c.x) < (r + c.r - 2) && (dirGravetat == 1 && y+r <= c.y-c.r+5 && y+r+vy >= c.y-c.r)) { 
        y = c.y - c.r - r; vy = c.vy; sobreSuport = true; x += c.vx * 0.8; 
      } 
    }
    if (esFill && altre != null && abs(x - altre.x) < (r + altre.r - 2) && (dirGravetat == 1 && y+r <= altre.y-altre.r+5 && y+r+vy >= altre.y-altre.r)) { 
      y = altre.y - altre.r - r; vy = altre.vy; sobreSuport = true; x += altre.vx * 0.8; 
    }

    if (!sobreSuport) {
      if(puedo(x, y + vy, pA, pB, pC)) { y += vy; aTerra = false; }
      else { if(dirGravetat == 1 && vy > 0) aTerra = true; vy = 0; }
    } else { aTerra = true; }
  }

  boolean puedo(float nx, float ny, boolean pA, boolean pB, boolean pC) {
    float m = r * 0.8; if (!check(nx-m, ny-m, pA, pB, pC) || !check(nx+m, ny+m, pA, pB, pC)) return false;
    for (Crate c : caixes) { if (rectIntersect(nx-r, ny-r, r*2, r*2, c.x-c.r, c.y-c.r, c.r*2, c.r*2)) { if (esFill) return false; else { float pushX = nx - x; if (c.puedo(c.x + pushX, c.y, pA, pB, pC)) { c.x += pushX; for (Crate a : caixes) if (a != c && a.estaSobre(c)) a.mourePerSuport(pushX, 0, pA, pB, pC); return true; } return false; } } }
    return true;
  }

  boolean check(float px, float py, boolean pA, boolean pB, boolean pC) {
    int c = floor(px / TILE_SIZE); int f = floor(py / TILE_SIZE);
    if(f < 0 || f >= ROWS || c < 0 || c >= COLS) return false;
    int t = grid[f][c];
    if(t == WALL || (t == GAP && py % TILE_SIZE < TILE_SIZE/2.0)) return false;
    if((t == DOOR_A && !pA) || (t == DOOR_B && !pB) || (t == DOOR_C && !pC)) return false;
    return true;
  }

  void display() { noStroke(); fill(col); rect(x-r, y-r, r*2, r*2, 4); fill(255); float ey = dirGravetat == 1 ? y-r+4 : y+r-12; rect(x-r+4, ey, 5, 5); rect(x+r-9, ey, 5, 5); }
}

void mousePressed() { if (isEditor) { int c = constrain(floor(mouseX / TILE_SIZE), 0, COLS - 1); int f = constrain(floor(mouseY / TILE_SIZE), 0, ROWS - 1); if (mouseButton == LEFT) grid[f][c] = selected; } }
void mouseDragged() { mousePressed(); }

void keyPressed() {
  if(key < 256) keys[key] = true; if(keyCode < 256) keysCode[keyCode] = true;
  if(isEditor) {
    if(key == 'p' || key == 'P') { pare.x = mouseX; pare.y = mouseY; } if(key == 'f' || key == 'F') { fill.x = mouseX; fill.y = mouseY; }
    if(key >= '0' && key <= '9') selected = int(key) - '0';
    if(key == 'c' || key == 'C') selected = BOX;
    if(key == 'v' || key == 'V') selected = GRAV_DOWN; if(key == 'b' || key == 'B') selected = GRAV_UP; if(key == 't' || key == 'T') selected = TRAMPOLINE;
  }
  if(key == 'e' || key == 'E') { isEditor = !isEditor; if(!isEditor) resetCaixes(); }
  if(key == 'g' || key == 'G') exportarCodi();
  if(key == 'i' || key == 'I') mostrarGuia = !mostrarGuia;
}

void keyReleased() { if(key < 256) keys[key] = false; if(keyCode < 256) keysCode[keyCode] = false; }

void dibuixarGuiaEditor() {
  pushMatrix(); translate(30, (ROWS * TILE_SIZE) + 40); 
  fill(0, 240); stroke(255, 100); strokeWeight(2); rect(0, 0, width - 60, height - (ROWS * TILE_SIZE) - 100, 15);
  fill(255); textAlign(LEFT); textSize(18); text("TAULELL DE DISSENY:", 30, 40); textSize(14);
  fill(#00FF00); text("1: Arbust | 2: Pas Estret | 3: Meta", 30, 75);
  fill(#FF4444); text("4: Placa Vermella | 7: Porta Vermella", 30, 105);
  fill(#4444FF); text("5: Placa Blava    | 8: Porta Blava", 330, 105);
  fill(#FFFF44); text("6: Placa Groga    | 9: Porta Groga", 630, 105);
  fill(#E2B13C); text("[P/F]: Posar Pare/Fill | [T]: Trampolí | [V/B]: Gravetat", 30, 140);
  fill(#8B5A2B); text("[C]: Caixa | [E]: Joc/Editor | [G]: Exportar", 330, 140);
  popMatrix();
}

void dibujarIndicadorEditor() { fill(255); text("OBJECTE: " + selected + " | 'G' per Exportar", 20, height - 30); }

boolean estaPisada(int tipo) {
  for(int f=0; f<ROWS; f++) {
    for(int c=0; c<COLS; c++) {
      if(grid[f][c] == tipo) {
        float cx = c*TILE_SIZE+TILE_SIZE/2; float cy = f*TILE_SIZE+TILE_SIZE/2;
        if(dist(pare.x, pare.y, cx, cy) < TILE_SIZE*0.75) return true;
        if(dist(fill.x, fill.y, cx, cy) < TILE_SIZE*0.75) return true;
        for(Crate cx_obj : caixes) if(dist(cx_obj.x, cx_obj.y, cx, cy) < TILE_SIZE*0.75) return true;
      }
    }
  }
  return false;
}

void exportarCodi() {
  println("\nint[][] NIVEL_CARGADO = {");
  for(int i=0; i<ROWS; i++){
    print("  {");
    for(int j=0; j<COLS; j++) print(grid[i][j] + (j==COLS-1?"":","));
    println("}" + (i==ROWS-1?"":","));
  }
  println("};");
}

void verificarVictoria() {
  if (grid[int(pare.y/TILE_SIZE)][int(pare.x/TILE_SIZE)] == GOAL && grid[int(fill.y/TILE_SIZE)][int(fill.x/TILE_SIZE)] == GOAL) {
    fill(255); textAlign(CENTER); textSize(48); text("VICTÒRIA!", width/2, height/4);
  }
}
