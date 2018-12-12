// url del servicio rest de donde se descargan los dibujos //<>//
final String URL = "http://plotter.ddns.net:8080";

// frecuancia de consulta por nuevos dibujos
final int FRECUENCIA_CONSULTA = 5000;

// control para el hilo que carga dibujos, sólo uno a la vez
boolean hiloTrabajando = false;

// dibujos
ArrayList<Dibujo> dibujos = new ArrayList<Dibujo>();

// provisional para ver algo de momento
int indicePintado = -1;

// colores
final color BLANCO = #FFFFFF;
final color NEGRO = #000000;
final color COLOR_FONDO = #F7F4D9;
final color ROJO = #FF0000;
final color AZUL = #0000FF;
final color GRIS = color(128);
final color COLOR_BARRA = #B7BDC1;
final color COLOR_TRAZO = AZUL;

// hay nuevos dibujos recién cargados
boolean nuevoDibujo;

// plóter simulado
final int MARGEN_PLOTTER = 100;
final int ANCHO_BARRA_PLOTTER = 10;
final int ANCHO_DIVISOR_PANTALLA = 10;
final int PAUSA_PINTADO_SIMULADOR = 3;
//final int GROSOR_TRAZO = 4;    // mejor que el trazo dependa del dibujo, si es de un svg interesa que sea más fino
int x0PlotterSimulado, y0PlotterSimulado, anchoPlotterSimulado, altoPlotterSimulado;

// dibujo está siendo pintado en estos momentos
boolean dibujoCompleto;

// medidas del plóter real (en pasos) 
// 1000 pasos de margen por cada lado, las medidas del largo en pasos del A4 que tomamos es 15290 (se puede afinar más adelante si hiciese falta)
final int MARGEN_PASOS = 1000;
final int X0_PLOTTER = MARGEN_PASOS;
final int Y0_PLOTTER = MARGEN_PASOS; 
final int ANCHO_PLOTTER = 10812 - 2 * MARGEN_PASOS; 
final int ALTO_PLOTTER = 15290 - 2 * MARGEN_PASOS;


String[] svgs = new String[]{
  "prueba1.svg",
  "prueba2.svg",
  "prueba3.svg",
  "prueba4.svg",
  "prueba5.svg",
  "prueba6.svg",
  "prueba7.svg",
  "prueba8.svg",
  "prueba9.svg",
  "prueba10.svg",
  "prueba11.svg",
};

void setup() {
  fullScreen();
  background(COLOR_FONDO);
  stroke(NEGRO);
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
  stroke(NEGRO);
  fill(BLANCO);
  rect(width - width / 3, MARGEN_PLOTTER, 10, height - 2 * MARGEN_PLOTTER);

  pintaFolioPlotter();
  pintarBarrasPlotter(x0PlotterSimulado, y0PlotterSimulado, false);
  
  dibujoCompleto = true;
  
  for(String svg : svgs){
   svg2Dibujo(svg); 
  }
}

void draw() {
  if (nuevoDibujo && dibujoCompleto) {
    nuevoDibujo = false;
    dibujoCompleto = false;
    indicePintado = dibujos.size() - 1;
    thread("recorreCurvasMarcandoPuntosVisibles");
  }
  if (indicePintado != -1 && !dibujoCompleto) {
    simularPlotter();
  }
}

/**
 * provisional
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

/**
 Recorre el dibujo pasado marcando todos sus puntos como invisibles.
 */
void marcarInvisible(Dibujo dibujo) { 
  for (Curva curva : dibujo.curvas) {
    for (Punto punto : curva.pixeles) {
      punto.visible = false;
    }
  }
}

/**
 Este método se debe ejecutar siempre desde un hilo distinto al principal.
 
 Recorre el dibujo que está siendo pintado en el plóter simulado, marcando 
 cada punto del mismo como visible. Tras marcar cada punto hará una pausa. 
 Si el dibujo que está siendo pintado ha cambiado, se termina automáticamente
 */
void recorreCurvasMarcandoPuntosVisibles() {
  int marcando = indicePintado;
  if (marcando != -1) {
    for (Curva curva : dibujos.get(marcando).curvas) {
      for (Punto punto : curva.pixeles) {
        if (indicePintado != marcando) {
          return;
        }
        punto.visible = true;
        delay(PAUSA_PINTADO_SIMULADOR);
      }
    }
  }
}

void cargaNuevosDibujos() {
  while (true) {
    JSONArray jsonArray = loadJSONArray(URL + "/dibujo/descargar");
    for (int i = 0; i < jsonArray.size(); i++) {   
      JSONObject dibujo = jsonArray.getJSONObject(i);
      long id = dibujo.isNull("id") ? -1 : dibujo.getInt("id");
      loadStrings(URL + "/dibujo/borrar?id=" + id);
      dibujos.add(parseaDibujo(dibujo));
    }
    nuevoDibujo = nuevoDibujo || jsonArray.size() > 0;
    delay(FRECUENCIA_CONSULTA);
  }
}

/**
 Simula trazar el dibujo cuyo índice es indicePintado, recorriendo todos sus
 puntos y pintándolos individualmente. Cuando se encuentra con un punto
 con la propiedad visible a false, pinta las barras del plóter y retorna.
 
 Si consigue recorrer el dibujo por completo, es decir, si todos sus puntos están marcados como 
 visibles, marca dibujoCompleto a true, de este modo no se debería de llamar de nuevo a este método 
 hasta que haya cambiado dibujo a pintar 
 */
void simularPlotter() {
  //println("dibujando:\t" + dibujo.id);
  Dibujo dibujo = dibujos.get(indicePintado);
  borraTercioPlotter();
  pintaFolioPlotter();
  strokeWeight(2); // TODO poner el grueso del trazo en plan dibujo.gruesoTrazo ahora que hay TSPArt, éstas se ven mejor con trazo fino
  stroke(COLOR_TRAZO);
  for (Curva curva : dibujo.curvas) {
    for (int i = 0; i < curva.pixeles.size(); i++) {   
      Punto punto = curva.pixeles.get(i);
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
  fill(COLOR_FONDO);
  noStroke();
  rect(x0PlotterSimulado - MARGEN_PLOTTER + ANCHO_DIVISOR_PANTALLA + pelin, 
    y0PlotterSimulado - MARGEN_PLOTTER, 
    anchoPlotterSimulado + 2 * MARGEN_PLOTTER - ANCHO_DIVISOR_PANTALLA - pelin, 
    altoPlotterSimulado + 2 * MARGEN_PLOTTER);
}

void pintaFolioPlotter() {
  fill(BLANCO);
  strokeWeight(2);
  stroke(NEGRO);
  rect(x0PlotterSimulado, y0PlotterSimulado, anchoPlotterSimulado, altoPlotterSimulado);
}

void pintarBarrasPlotter(int x, int y, boolean lapiz) {
  int sobresale = 10;
  stroke(NEGRO);
  strokeWeight(2);        
  fill(COLOR_BARRA);
  rect(x - ANCHO_BARRA_PLOTTER / 2, 
    y0PlotterSimulado - sobresale, 
    ANCHO_BARRA_PLOTTER, 
    altoPlotterSimulado + 2 * sobresale);
  rect(x0PlotterSimulado - sobresale, 
    y - ANCHO_BARRA_PLOTTER / 2, 
    anchoPlotterSimulado + 2 * sobresale, 
    ANCHO_BARRA_PLOTTER);
  if (lapiz) {
    fill(ROJO);
    ellipse(x, y, 2 * ANCHO_BARRA_PLOTTER, 2 * ANCHO_BARRA_PLOTTER);
  }
}
