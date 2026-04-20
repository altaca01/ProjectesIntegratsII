void mousePressed() {
  if (!isEditor) return;

  int c = constrain(floor(mouseX / TILE_SIZE), 0, COLS - 1);
  int f = constrain(floor(mouseY / TILE_SIZE), 0, ROWS - 1);
  if (mouseButton == LEFT) {
    grid[f][c] = selected;
  }
}

void mouseDragged() {
  mousePressed();
}

void keyPressed() {
  if (key < 256) keys[key] = true;
  if (keyCode < 256) keysCode[keyCode] = true;

  if (isEditor) {
    if (key == 'p' || key == 'P') {
      pare.x = mouseX;
      pare.y = mouseY;
    }
    if (key == 'f' || key == 'F') {
      fill.x = mouseX;
      fill.y = mouseY;
    }
    if (key >= '0' && key <= '9') selected = int(key) - '0';
    if (key == 'c' || key == 'C') selected = BOX;
    if (key == 'v' || key == 'V') selected = GRAV_FLIP;
    if (key == 't' || key == 'T') selected = TRAMPOLINE;
  }

  if (key == 'e' || key == 'E') {
    isEditor = !isEditor;
    if (!isEditor) {
      copiaGrid(gridMemoriaJoc, grid);
      instanciaInterruptorsDesDeGrid();
      resetCaixes();
      gravPadPisat = false;
    } else {
      restauraGridDesMemoria();
      gravPadPisat = false;
      resetCaixes();
    }
  }
  if (key == 'g' || key == 'G') {
    exportarNivell();
  }
  if (key == 'i' || key == 'I') mostrarGuia = !mostrarGuia;

  if (!isEditor && key == ' ' && jugadorsAMeta() && NIVELLS != null && indexNivellActual < NIVELLS.length - 1) {
    passarSeguentNivell();
  }
}

void keyReleased() {
  if (key < 256) keys[key] = false;
  if (keyCode < 256) keysCode[keyCode] = false;
}

void dibuixarGuiaEditor() {
  pushMatrix();
  translate(30, (ROWS * TILE_SIZE) + 40);
  fill(0, 240);
  stroke(255, 100);
  strokeWeight(2);
  rect(0, 0, width - 60, height - (ROWS * TILE_SIZE) - 100, 15);

  fill(255);
  textAlign(LEFT);
  textSize(18);
  text("TAULELL DE DISSENY:", 30, 40);
  textSize(14);
  fill(#00FF00);
  text("1: Arbust | 2: Pas Estret | 3: Meta", 30, 75);
  fill(#FF4444);
  text("4: Placa Vermella | 7: Porta Vermella", 30, 105);
  fill(#4444FF);
  text("5: Placa Blava    | 8: Porta Blava", 330, 105);
  fill(#FFFF44);
  text("6: Placa Groga    | 9: Porta Groga", 630, 105);
  fill(#E2B13C);
  text("[P/F]: Posar Pare/Fill | [T]: Trampolí | [V]: Commutar gravetat", 30, 140);
  fill(#8B5A2B);
  text("[C]: Caixa | [E]: Joc/Editor | [G]: exportar tauler + pos. P/F → spawnNivells", 330, 140);
  popMatrix();
}

void dibuixarIndicadorEditor() {
  fill(255);
  text("OBJECTE: " + selected + " | 'G' per exportar", 20, height - 30);
}

void exportarNivell() {
  if (!isEditor) {
    println("Obre l'editor (tecla E) per exportar el disseny del nivell.");
    return;
  }

  String[] linies = new String[ROWS + 2];
  linies[0] = "int[][] NIVELL_X = {  // reanomena (ex.: NIVELL_3) i afegeix a NIVELLS a ProjFinal.pde";
  for (int i = 0; i < ROWS; i++) {
    String fila = "  {";
    for (int j = 0; j < COLS; j++) {
      fila += grid[i][j];
      if (j < COLS - 1) fila += ",";
    }
    fila += "}" + (i == ROWS - 1 ? "" : ",");
    linies[i + 1] = fila;
  }
  linies[ROWS + 1] = "};";

  float px = pare.x / TILE_SIZE;
  float py = pare.y / TILE_SIZE;
  float fx = fill.x / TILE_SIZE;
  float fy = fill.y / TILE_SIZE;
  String filaSpawn =
    "  { " + nf(px, 0, 3).replace(',', '.') + "f, " + nf(py, 0, 3).replace(',', '.') + "f, " + nf(fx, 0, 3).replace(',', '.') + "f, " + nf(fy, 0, 3).replace(',', '.') + "f },  // nivell " + (indexNivellActual + 1) + " (índex " + indexNivellActual + " a spawnNivells)";

  String[] liniesComplet = new String[linies.length + 5];
  arrayCopy(linies, liniesComplet);
  liniesComplet[linies.length] = "";
  liniesComplet[linies.length + 1] = "// --- Punt de partida (pare P + ratolí, fill F + ratolí) — substitueix la fila " + indexNivellActual + " de spawnNivells a Nivells.pde:";
  liniesComplet[linies.length + 2] = filaSpawn;
  liniesComplet[linies.length + 3] = "";
  liniesComplet[linies.length + 4] = "// Les coordenades són en unitats de casella (1 = una casella); escalen si canvies la mida de la finestra.";

  saveStrings("nivell_export.txt", liniesComplet);

  println("\n--- Exportació del nivell ---");
  println("S'ha desat el codi a la carpeta del sketch: nivell_export.txt (mapa + fila spawnNivells[" + indexNivellActual + "])");
  println("Enganxa el mapa a NIVELL_N i la fila de spawn a spawnNivells (mateix índex que el nivell editat).");
  println("(També es mostra a sota per copiar de la consola.)\n");
  for (int k = 0; k < liniesComplet.length; k++) {
    println(liniesComplet[k]);
  }
}

void verificarVictoria() {
  if (!jugadorsAMeta()) return;
  fill(255);
  textAlign(CENTER);
  textSize(48);
  text("VICTÒRIA!", width/2, height/4);
  if (NIVELLS != null && indexNivellActual < NIVELLS.length - 1) {
    textSize(20);
    text("Prem ESPAI per al nivell " + (indexNivellActual + 2), width/2, height/4 + 55);
  } else {
    textSize(22);
    text("Has completat tots els nivells!", width/2, height/4 + 55);
  }
}
