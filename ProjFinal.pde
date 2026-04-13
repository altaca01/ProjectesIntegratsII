/**
 * THE BOND: EXPEDITION - INTEGRAL VERSION
 * - Resolució dinàmica adaptada al monitor.
 * - Sistema de puzles A, B i C totalment funcional.
 * - Cooperació: El Fill pot saltar sobre el Pare i sobre Caixes.
 * - Caixes de fusta ('C'): Només el Pare les pot empènyer. Activen botons.
 * - FÍSIQUES REALS: El "Pas Estret" ('2') només deixa passar el fill per mida.
 * - Editor de nivells amb exportació a consola ('G').
 * - Reposicionament de personatges a l'editor ('P' i 'F').
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

Player pare, fill;
ArrayList<Crate> caixes = new ArrayList<Crate>();
boolean[] keys = new boolean[256];
boolean[] keysCode = new boolean[256];

// =========================================================
// SLOT DE CÀRREGA: Enganxa aquí el codi exportat amb 'G'
// =========================================================
int[][] NIVEL_CARGADO = {
  {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
  {1,0,0,0,0,0,0,0,0,2,2,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,1,1,1,1,7,7,1,1,1,1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,4,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,3,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
};

void settings() {
  fullScreen();
}

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
        if (f < NIVEL_CARGADO.length && c < NIVEL_CARGADO[0].length) {
          grid[f][c] = NIVEL_CARGADO[f][c];
        }
      }
    }
  } else {
    for(int i=0; i<ROWS; i++) { grid[i][0] = 1; grid[i][COLS-1] = 1; }
    for(int j=0; j<COLS; j++) { grid[0][j] = 1; grid[ROWS-1][j] = 1; }
  }
}

void resetCaixes() {
  caixes.clear();
  for(int f=0; f<ROWS; f++) {
    for(int c=0; c<COLS; c++) {
      if(grid[f][c] == BOX) {
        caixes.add(new Crate(c*TILE_SIZE + TILE_SIZE/2, f*TILE_SIZE + TILE_SIZE/2, TILE_SIZE*0.4));
      }
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
  
  dibujarNivel(pA, pB, pC);
  
  if (!isEditor) {
    for (Crate c : caixes) { c.update(pA, pB, pC); c.display(); }
    pare.update(pA, pB, pC, null); 
    fill.update(pA, pB, pC, pare);
    verificarVictoria();
  }
  
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
      float x = c * TILE_SIZE; 
      float y = f * TILE_SIZE;
      int t = grid[f][c];
      
      if (t != WALL && imgGrass != null) image(imgGrass, x, y, TILE_SIZE + 0.5, TILE_SIZE + 0.5);
      if (isEditor) { stroke(255, 12); noFill(); rect(x, y, TILE_SIZE, TILE_SIZE); }
      
      noStroke();
      switch(t) {
        case WALL:
          if (imgArbust != null) image(imgArbust, x, y, TILE_SIZE + 0.5, TILE_SIZE + 0.5);
          else { fill(60); rect(x, y, TILE_SIZE, TILE_SIZE); }
          break;
        case GAP: // ARA ÉS UN PAS ESTRET (Meitat superior sòlida)
          fill(70); rect(x, y, TILE_SIZE, TILE_SIZE/2); // Bloc gris
          fill(50); rect(x, y+TILE_SIZE/2-4, TILE_SIZE, 4); // Línia de base
          break;
        case GOAL: fill(0, 255, 0, 70); rect(x, y, TILE_SIZE, TILE_SIZE); break;
        case PLATE_A: fill(pA ? #FF4444 : #880000); rect(x+TILE_SIZE*0.2, y+TILE_SIZE*0.7, TILE_SIZE*0.6, TILE_SIZE*0.2, 4); break;
        case PLATE_B: fill(pB ? #4444FF : #000088); rect(x+TILE_SIZE*0.2, y+TILE_SIZE*0.7, TILE_SIZE*0.6, TILE_SIZE*0.2, 4); break;
        case PLATE_C: fill(pC ? #FFFF44 : #888800); rect(x+TILE_SIZE*0.2, y+TILE_SIZE*0.7, TILE_SIZE*0.6, TILE_SIZE*0.2, 4); break;
        case DOOR_A: if (!pA) { fill(#880000, 200); rect(x, y, TILE_SIZE, TILE_SIZE); stroke(#FF4444); rect(x+2,y+2,TILE_SIZE-4,TILE_SIZE-4); } break;
        case DOOR_B: if (!pB) { fill(#000088, 200); rect(x, y, TILE_SIZE, TILE_SIZE); stroke(#4444FF); rect(x+2,y+2,TILE_SIZE-4,TILE_SIZE-4); } break;
        case DOOR_C: if (!pC) { fill(#888800, 200); rect(x, y, TILE_SIZE, TILE_SIZE); stroke(#FFFF44); rect(x+2,y+2,TILE_SIZE-4,TILE_SIZE-4); } break;
        case BOX: 
          if (isEditor) { 
            fill(#8B5A2B); stroke(#5C3A21); strokeWeight(2);
            rect(x+4, y+4, TILE_SIZE-8, TILE_SIZE-8, 4);
            line(x+4, y+4, x+TILE_SIZE-4, y+TILE_SIZE-4); line(x+TILE_SIZE-4, y+4, x+4, y+TILE_SIZE-4);
            noStroke();
          } 
          break;
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
    vy += gravetatForca * dirGravetat;
    vx *= friccio;

    if(puedo(x + vx, y, pA, pB, pC)) x += vx; else vx = 0;

    boolean sobrePlayer = false;
    if (abs(x - pare.x) < (r + pare.r - 2)) {
      if (dirGravetat == 1 && vy > 0 && y+r <= pare.y-pare.r+5 && y+r+vy >= pare.y-pare.r) { y = pare.y - pare.r - r; sobrePlayer = true; }
      else if (dirGravetat == -1 && vy < 0 && y-r >= pare.y+pare.r-5 && y-r+vy <= pare.y+pare.r) { y = pare.y + pare.r + r; sobrePlayer = true; }
    }
    if (abs(x - fill.x) < (r + fill.r - 2)) {
      if (dirGravetat == 1 && vy > 0 && y+r <= fill.y-fill.r+5 && y+r+vy >= fill.y-fill.r) { y = fill.y - fill.r - r; sobrePlayer = true; }
      else if (dirGravetat == -1 && vy < 0 && y-r >= fill.y+fill.r-5 && y-r+vy <= fill.y+fill.r) { y = fill.y + fill.r + r; sobrePlayer = true; }
    }

    if (sobrePlayer) {
      vy = 0; aTerra = true;
    } else if(puedo(x, y + vy, pA, pB, pC)) {
      y += vy; aTerra = false;
    } else {
      if((dirGravetat == 1 && vy > 0) || (dirGravetat == -1 && vy < 0)) aTerra = true;
      vy = 0;
    }
  }

  boolean puedo(float nx, float ny, boolean pA, boolean pB, boolean pC) {
    float m = r * 0.8; 
    boolean ok = check(nx-m, ny-m, pA, pB, pC) && check(nx+m, ny-m, pA, pB, pC) && 
                 check(nx-m, ny+m, pA, pB, pC) && check(nx+m, ny+m, pA, pB, pC);
    if (!ok) return false;
    if (rectIntersect(nx-r, ny-r, r*2, r*2, fill.x-fill.r, fill.y-fill.r, fill.r*2, fill.r*2)) return false;
    return true;
  }

  boolean check(float px, float py, boolean pA, boolean pB, boolean pC) {
    int c = floor(px / TILE_SIZE); 
    int f = floor(py / TILE_SIZE);
    if(f < 0 || f >= ROWS || c < 0 || c >= COLS) return false;
    int t = grid[f][c];
    if(t == WALL) return false;
    if(t == GAP) { // Sòlid si cau a la meitat superior del bloc
      float localY = py % TILE_SIZE;
      if (localY < TILE_SIZE/2.0) return false;
    }
    if(t == DOOR_A && !pA) return false;
    if(t == DOOR_B && !pB) return false;
    if(t == DOOR_C && !pC) return false;
    return true;
  }

  void display() {
    pushMatrix();
    translate(x, y);
    fill(#8B5A2B); stroke(#5C3A21); strokeWeight(2);
    rect(-r, -r, r*2, r*2, 4);
    line(-r, -r, r, r); line(r, -r, -r, r);
    noStroke();
    popMatrix();
  }
}

class Player {
  float x, y, r, vx, vy;
  color col; boolean esFill, aTerra;

  Player(float _x, float _y, float _r, color _c, boolean _h) {
    x=_x; y=_y; r=_r; col=_c; esFill=_h;
  }

  void update(boolean pA, boolean pB, boolean pC, Player altre) {
    float ax = 0;
    float speed = esFill ? TILE_SIZE*0.015 : TILE_SIZE*0.011;
    float jump = esFill ? TILE_SIZE*0.25 : TILE_SIZE*0.22;

    if(!esFill) {
      if(keys['a'] || keys['A']) ax -= speed;
      if(keys['d'] || keys['D']) ax += speed;
      if((keys['w'] || keys['W']) && aTerra) { vy = -jump * dirGravetat; aTerra = false; }
    } else {
      if(keysCode[LEFT]) ax -= speed;
      if(keysCode[RIGHT]) ax += speed;
      if(keysCode[UP] && aTerra) { vy = -jump * dirGravetat; aTerra = false; }
    }

    vx = (vx + ax) * friccio;
    vy += gravetatForca * dirGravetat;

    if(puedo(x + vx, y, pA, pB, pC)) x += vx; else vx = 0;

    boolean sobreSuport = false;

    if (esFill && altre != null) {
      float distH = abs(x - altre.x);
      if (distH < (r + altre.r - 2)) { 
        if (dirGravetat == 1 && vy > 0 && y+r <= altre.y-altre.r+5 && y+r+vy >= altre.y-altre.r) {
          y = altre.y - altre.r - r; sobreSuport = true; x += altre.vx * 0.8;
        } else if (dirGravetat == -1 && vy < 0 && y-r >= altre.y+altre.r-5 && y-r+vy <= altre.y+altre.r) {
          y = altre.y + altre.r + r; sobreSuport = true; x += altre.vx * 0.8;
        }
      }
    }
    
    for (Crate c : caixes) {
      float distH = abs(x - c.x);
      if (distH < (r + c.r - 2)) { 
        if (dirGravetat == 1 && vy > 0 && y+r <= c.y-c.r+5 && y+r+vy >= c.y-c.r) {
          y = c.y - c.r - r; sobreSuport = true; x += c.vx * 0.8;
        } else if (dirGravetat == -1 && vy < 0 && y-r >= c.y+c.r-5 && y-r+vy <= c.y+c.r) {
          y = c.y + c.r + r; sobreSuport = true; x += c.vx * 0.8;
        }
      }
    }

    if (sobreSuport) { 
      vy = 0; aTerra = true; 
    } else if(puedo(x, y + vy, pA, pB, pC)) { 
      y += vy; aTerra = false; 
    } else { 
      if((dirGravetat == 1 && vy > 0) || (dirGravetat == -1 && vy < 0)) aTerra = true; 
      vy = 0; 
    }
  }

  boolean puedo(float nx, float ny, boolean pA, boolean pB, boolean pC) {
    float m = r * 0.8; 
    boolean ok = check(nx-m, ny-m, pA, pB, pC) && check(nx+m, ny-m, pA, pB, pC) && 
                 check(nx-m, ny+m, pA, pB, pC) && check(nx+m, ny+m, pA, pB, pC);
    if (!ok) return false;
    
    for (Crate c : caixes) {
      if (rectIntersect(nx-r, ny-r, r*2, r*2, c.x-c.r, c.y-c.r, c.r*2, c.r*2)) {
        if (esFill) {
          return false; 
        } else {
          if (abs(nx - x) > 0.01 && abs(ny - y) < 0.01) { 
            float pushX = nx - x;
            if (c.puedo(c.x + pushX, c.y, pA, pB, pC)) {
              boolean hitOther = false;
              for (Crate other : caixes) {
                if (c != other && rectIntersect(c.x+pushX-c.r, c.y-c.r, c.r*2, c.r*2, other.x-other.r, other.y-other.r, other.r*2, other.r*2)) {
                  hitOther = true; break;
                }
              }
              if (!hitOther) {
                c.x += pushX; 
                return true; 
              }
            }
          }
          return false; 
        }
      }
    }
    return true;
  }

  boolean check(float px, float py, boolean pA, boolean pB, boolean pC) {
    int c = floor(px / TILE_SIZE); 
    int f = floor(py / TILE_SIZE);
    if(f < 0 || f >= ROWS || c < 0 || c >= COLS) return false;
    int t = grid[f][c];
    if(t == WALL) return false;
    
    // APLICACIÓ FÍSICA: Si el punt toca la meitat superior del bloc 2, és xoc.
    if(t == GAP) { 
      float localY = py % TILE_SIZE;
      if (localY < TILE_SIZE/2.0) return false;
    }
    
    if(t == DOOR_A && !pA) return false;
    if(t == DOOR_B && !pB) return false;
    if(t == DOOR_C && !pC) return false;
    return true;
  }

  void display() {
    noStroke(); fill(col);
    rect(x-r, y-r, r*2, r*2, 4); 
    fill(255); 
    float ey = dirGravetat == 1 ? y-r+4 : y+r-12;
    rect(x-r+4, ey, 5, 5); rect(x+r-9, ey, 5, 5);
  }
}

void mousePressed() {
  if (isEditor) {
    int c = constrain(floor(mouseX / TILE_SIZE), 0, COLS - 1);
    int f = constrain(floor(mouseY / TILE_SIZE), 0, ROWS - 1);
    if (mouseButton == LEFT) grid[f][c] = selected;
  } else if (mouseButton == RIGHT) {
    dirGravetat *= -1;
  }
}

void mouseDragged() { mousePressed(); }

void keyPressed() {
  if(key < 256) keys[key] = true;
  if(keyCode < 256) keysCode[keyCode] = true;
  
  if(isEditor) {
    if(key == 'p' || key == 'P') { pare.x = mouseX; pare.y = mouseY; pare.vx = 0; pare.vy = 0; }
    if(key == 'f' || key == 'F') { fill.x = mouseX; fill.y = mouseY; fill.vx = 0; fill.vy = 0; }
  }

  if(key == 'i' || key == 'I') mostrarGuia = !mostrarGuia;
  if(key == 'e' || key == 'E') { 
    isEditor = !isEditor; 
    if(!isEditor) resetCaixes(); 
  }
  if(key == 'q' || key == 'Q') exit();
  if(key >= '0' && key <= '9') selected = int(key) - '0';
  if(key == 'c' || key == 'C') selected = BOX; 
  if(key == 'g' || key == 'G') exportarCodi();
}

void keyReleased() {
  if(key < 256) keys[key] = false;
  if(keyCode < 256) keysCode[keyCode] = false;
}

void dibuixarGuiaEditor() {
  pushMatrix();
  translate(30, (ROWS * TILE_SIZE) + 40); 
  fill(0, 240); stroke(255, 100); strokeWeight(2);
  rect(0, 0, width - 60, height - (ROWS * TILE_SIZE) - 100, 15);
  fill(255); textAlign(LEFT); textSize(18);
  text("TAULELL DE DISSENY:", 30, 40);
  textSize(14);
  
  fill(#00FF00); text("1: Arbust | 2: Pas Estret | 3: Meta", 30, 75);
  fill(#FF4444); text("4: Placa Vermella | 7: Porta Vermella", 30, 105);
  fill(#4444FF); text("5: Placa Blava    | 8: Porta Blava", 330, 105);
  fill(#FFFF44); text("6: Placa Groga    | 9: Porta Groga", 630, 105);
  
  fill(#E2B13C); text("[P]: Posar Pare aquí | [F]: Posar Fill aquí", 30, 140);
  fill(#8B5A2B); text("[C]: Caixa de fusta (Empènyer amb el Pare)", 330, 140);
  
  fill(200);
  text("[0] Esborrar | [E] Joc/Editor | [G] Exportar | [Q] Sortir", 30, 175);
  popMatrix();
}

void dibujarIndicadorEditor() {
  fill(255); textSize(14); textAlign(LEFT);
  String objName = (selected == BOX) ? "CAIXA" : str(selected);
  text("OBJECTE SELECCIONAT: " + objName + " | 'G' per Exportar", 20, height - 30);
  noFill(); stroke(255, 255, 0); 
  rect(floor(mouseX/TILE_SIZE)*TILE_SIZE, floor(mouseY/TILE_SIZE)*TILE_SIZE, TILE_SIZE, TILE_SIZE);
}

boolean estaPisada(int tipo) {
  for(int f=0; f<ROWS; f++) {
    for(int c=0; c<COLS; c++) {
      if(grid[f][c] == tipo) {
        float cx = c*TILE_SIZE+TILE_SIZE/2;
        float cy = f*TILE_SIZE+TILE_SIZE/2;
        if(dist(pare.x, pare.y, cx, cy) < TILE_SIZE*0.75) return true;
        if(dist(fill.x, fill.y, cx, cy) < TILE_SIZE*0.75) return true;
        for(Crate caixa : caixes) {
          if(dist(caixa.x, caixa.y, cx, cy) < TILE_SIZE*0.75) return true;
        }
      }
    }
  }
  return false;
}

void exportarCodi() {
  println("\n--- COPIA EL TEU NIVELL ---");
  print("int[][] NIVEL_CARGADO = {");
  for(int i=0; i<ROWS; i++){
    print("\n  {");
    for(int j=0; j<COLS; j++) print(grid[i][j] + (j==COLS-1?"":","));
    print("}" + (i==ROWS-1?"":","));
  }
  println("\n};");
}

void verificarVictoria() {
  if (grid[int(pare.y/TILE_SIZE)][int(pare.x/TILE_SIZE)] == GOAL && 
      grid[int(fill.y/TILE_SIZE)][int(fill.x/TILE_SIZE)] == GOAL) {
    fill(255); textAlign(CENTER); textSize(48); text("VICTÒRIA!", width/2, height/4);
  }
}
