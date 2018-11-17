// url del servicio rest de donde se descargan los dibujos //<>//
final String URL = "http://plotter.ddns.net:8080";

// frecuancia de consulta por nuevos dibujos
final int FRECUENCIA_CONSULTA = 5000;

// guarda la id del último dibujo descargado
long ultimaId = -1;

// control para el hilo que carga dibujos, sólo uno a la vez
boolean hiloTrabajando = false;

// dibujos
ArrayList<Dibujo> dibujos = new ArrayList<Dibujo>();

// provisional para ver algo de momento
int indicePintado = -1;

// colores
color blanco = #FFFFFF;
color negro = #000000;
color colorFondo = #F7F4D9;
color rojo = #FF0000;
color azul = #0000FF;
color gris = color(128);
color colorBarra = #B7BDC1;
color colorTrazo = azul;

// hay nuevos dibujos recién cargados
boolean nuevoDibujo;

// plóter simulado
final int MARGEN_PLOTTER = 100;
final int ANCHO_BARRA_PLOTTER = 10;
final int ANCHO_DIVISOR_PANTALLA = 10;
final int VELOCIDAD_PINTADO_SIMULADOR = 3;
int x0PlotterSimulado, y0PlotterSimulado, anchoPlotterSimulado, altoPlotterSimulado;

// dibujo está siendo pintado en estos momentos
boolean dibujoCompleto;

// medidas del plóter real (en pasos)
final int X0_PLOTTER_REAL = -1;
final int Y0_PLOTTER_REAL = -1; 
final int ANCHO_PLOTTER_REAL = -1; 
final int ALTO_PLOTTER_REAL = -1;

void setup() {
  fullScreen();
  background(colorFondo);
  stroke(negro);
  thread("cargaNuevosDibujos");

  // división de la pantalla
  strokeWeight(2);
  rect(width - width / 3, MARGEN_PLOTTER, ANCHO_DIVISOR_PANTALLA, height - 2 * MARGEN_PLOTTER);

  // medidas del plotter simulado en pantalla
  x0PlotterSimulado = width -  width / 3 + MARGEN_PLOTTER;
  anchoPlotterSimulado = width / 3 - 2 * MARGEN_PLOTTER;
  altoPlotterSimulado = (int) (sqrt(2) * anchoPlotterSimulado);
  y0PlotterSimulado = height / 2 - altoPlotterSimulado / 2;

  // divisor vertical zona simulador plóter  
  stroke(negro);
  fill(blanco);
  rect(width - width / 3, MARGEN_PLOTTER, 10, height - 2 * MARGEN_PLOTTER);

  pintaFolioPlotter();
  pintarBarrasPlotter(x0PlotterSimulado /*- 2 * ANCHO_BARRA_PLOTTER*/, y0PlotterSimulado /*- 2 * ANCHO_BARRA_PLOTTER*/, false);
}

void draw() {
  if (nuevoDibujo) {
    nuevoDibujo = false;
    dibujoCompleto = false;
    indicePintado = dibujos.size() - 1;
    thread("recorreCurvasMarcandoPuntosVisibles");
  }
  if (indicePintado != -1 && !dibujoCompleto) {
    simularPlotter(dibujos.get(indicePintado));
  }
}

/**
 provisional
 */
void keyPressed() {
  if (dibujos.size() > 0 && (keyCode == RIGHT || keyCode == LEFT)) {
    if (keyCode == LEFT) {
      indicePintado = indicePintado == 0 ? dibujos.size() - 1 : indicePintado - 1;
    } else {      
      indicePintado = indicePintado == dibujos.size() - 1 ? 0 : indicePintado + 1;
    }
    marcarInvisible(dibujos.get(indicePintado));
    thread("recorreCurvasMarcandoPuntosVisibles");
    dibujoCompleto = false;
  }
}

void marcarInvisible(Dibujo dibujo) { 
  for (Curva curva : dibujo.curvas) {
    for (Punto punto : curva.puntosPixeles) {
      punto.visible = false;
    }
  }
}

/**
 Me parece un poco marranada ...
 */
void recorreCurvasMarcandoPuntosVisibles() {
  int marcando = indicePintado;
  if (marcando != -1) {
    for (Curva curva : dibujos.get(marcando).curvas) {
      for (Punto punto : curva.puntosPixeles) {
        if (indicePintado != marcando) {
          return;
        }
        punto.visible = true;
        delay(VELOCIDAD_PINTADO_SIMULADOR);
      }
    }
  }
}

void cargaNuevosDibujos() {
  while (true) {
    JSONArray jsonArray = loadJSONArray(URL + "/dibujo/descargar" + (ultimaId == -1 ? "" : "?last=" + (ultimaId)));
    for (int i = 0; i < jsonArray.size(); i++) {    
      JSONObject dibujo = jsonArray.getJSONObject(i);
      ultimaId = dibujo.isNull("id") ? ultimaId : dibujo.getInt("id");
      dibujos.add(parseaDibujo(dibujo));
      // if (ultimaId == 10) { saveJSONObject(dibujo, "data/trump.json"); } // <-- si quieres guardar un dibujo ya que en el servicio rest no hay persistencia, al menos de momento
    }
    nuevoDibujo = nuevoDibujo || jsonArray.size() > 0;
    delay(FRECUENCIA_CONSULTA);
  }
}

void simularPlotter(Dibujo dibujo) {
  //println("dibujando:\t" + dibujo.id);
  borraTercioPlotter();
  pintaFolioPlotter();
  strokeWeight(5);
  stroke(colorTrazo);
  for (Curva curva : dibujo.curvas) {
    for (int i = 0; i < curva.puntosPixeles.size(); i++) {   
      Punto punto = curva.puntosPixeles.get(i);
      if (punto.visible && curva.pintable) {
        point(punto.x, punto.y);
      } else if (!punto.visible) {
        pintarBarrasPlotter(punto.x, punto.y, curva.pintable);
        return;
      }
    }
  }
  dibujoCompleto = true;
  pintarBarrasPlotter(x0PlotterSimulado, y0PlotterSimulado, false);
}

void borraTercioPlotter() {
  int pelin = 5;
  fill(colorFondo);
  noStroke();
  rect(x0PlotterSimulado - MARGEN_PLOTTER + ANCHO_DIVISOR_PANTALLA + pelin, 
    y0PlotterSimulado - MARGEN_PLOTTER, 
    anchoPlotterSimulado + 2 * MARGEN_PLOTTER - ANCHO_DIVISOR_PANTALLA - pelin, 
    altoPlotterSimulado + 2 * MARGEN_PLOTTER);
}

void pintaFolioPlotter() {
  fill(blanco);
  strokeWeight(2);
  stroke(negro);
  rect(x0PlotterSimulado, y0PlotterSimulado, anchoPlotterSimulado, altoPlotterSimulado);
}

void pintarBarrasPlotter(int x, int y, boolean lapiz) {
  int sobresale = 10;
  stroke(negro);
  strokeWeight(2);        
  fill(colorBarra);
  rect(x - ANCHO_BARRA_PLOTTER / 2, 
    y0PlotterSimulado - sobresale, 
    ANCHO_BARRA_PLOTTER, 
    altoPlotterSimulado + 2 * sobresale);
  rect(x0PlotterSimulado - sobresale, 
    y - ANCHO_BARRA_PLOTTER / 2, 
    anchoPlotterSimulado + 2 * sobresale, 
    ANCHO_BARRA_PLOTTER);
  if (lapiz) {
    fill(rojo);
    ellipse(x, y, 2 * ANCHO_BARRA_PLOTTER, 2 * ANCHO_BARRA_PLOTTER);
  }
}
