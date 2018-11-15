// url del servicio rest de donde se descargan los dibujos //<>//
final String URL = "http://plotter.ddns.net:8080";

// frecuancia de consulta por nuevos dibujos
final long FRECUENCIA_CONSULTA = 5000;

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
color colorBarra = gris;
color colorTrazo = azul;

// hay nuevos dibujos recién cargados
boolean nuevoDibujo;

// ***** sección de la simulación del plotter en la pantalla
// medidas
final int MARGEN_PLOTTER = 100;
final int ANCHO_BARRA_PLOTTER = 10;
final int ANCHO_DIVISOR_PANTALLA = 10;
int x0Plotter, y0Plotter, anchoPlotter, altoPlotter;

// dibujo está siendo pintado en estos momentos
boolean dibujoCompleto = true;

void setup() {
  fullScreen();
  //size(500, 707);
  background(colorFondo);
  stroke(negro);
  thread("cargaNuevosDibujos");

  // división de la pantalla
  strokeWeight(2);
  rect(width - width / 3, MARGEN_PLOTTER, ANCHO_DIVISOR_PANTALLA, height - 2 * MARGEN_PLOTTER);

  // medidas del plotter simulado en pantalla
  x0Plotter = width -  width / 3 + MARGEN_PLOTTER;
  anchoPlotter = width / 3 - 2 * MARGEN_PLOTTER;
  altoPlotter = (int) (sqrt(2) * anchoPlotter);
  y0Plotter = height / 2 - altoPlotter / 2;

  // divisor vertical zona simulador plóter  
  stroke(negro);
  fill(blanco);
  rect(width - width / 3, MARGEN_PLOTTER, 10, height - 2 * MARGEN_PLOTTER);

  pintaFolioPlotter();
  pintarBarrasPlotter(x0Plotter - 2 * ANCHO_BARRA_PLOTTER, y0Plotter - 2 * ANCHO_BARRA_PLOTTER, false);
}

void draw() {
  if (nuevoDibujo) {
    nuevoDibujo = false;
    dibujoCompleto = false;
    indicePintado = dibujos.size() - 1;
    thread("recorreCurvasMarcandoPuntosVisibles");
  }
  if (!dibujoCompleto) {
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
    for (Curva curva : dibujos.get(indicePintado).curvas) {
      for (Punto punto : curva.puntosPixeles) {
        punto.visible = false;
      }
    }
    thread("recorreCurvasMarcandoPuntosVisibles");
    dibujoCompleto = false;
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
        if ( indicePintado != marcando) {
          return;
        }
        punto.visible = true;
        delay(2);
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
    delay(5000);
  }
}

void simularPlotter(Dibujo dibujo) {
  //println("dibujando:\t" + dibujo.id);
  borraTercioPlotter();
  pintaFolioPlotter();
  strokeWeight(5);
  for (Curva curva : dibujo.curvas) {
    if (curva.puntosPixeles.size() == 1) {
      if (curva.puntosPixeles.get(0).visible) {
        if (curva.pintable) {
          stroke(colorTrazo);
          line(curva.puntosPixeles.get(0).x, curva.puntosPixeles.get(0).y, curva.puntosPixeles.get(0).x, curva.puntosPixeles.get(0).y);
        }
      } else {
        pintarBarrasPlotter(curva.puntosPixeles.get(0).x, curva.puntosPixeles.get(0).y, curva.pintable);
        return;
      }
    }
    for (int i = 1; i < curva.puntosPixeles.size(); i++) {      
      if (curva.puntosPixeles.get(i - 1).visible) {
        if (curva.pintable) {
          stroke(colorTrazo);
          line(curva.puntosPixeles.get(i - 1).x, curva.puntosPixeles.get(i - 1).y, curva.puntosPixeles.get(i).x, curva.puntosPixeles.get(i).y);
        }
      } else {
        pintarBarrasPlotter(curva.puntosPixeles.get(i - 1).x, curva.puntosPixeles.get(i - 1).y, curva.pintable);
        return;
      }
    }
  }
  dibujoCompleto = true;
  pintarBarrasPlotter(x0Plotter - 2 * ANCHO_BARRA_PLOTTER, y0Plotter - 2 * ANCHO_BARRA_PLOTTER, false);
}

void borraTercioPlotter() {
  fill(colorFondo);
  noStroke();
  rect(x0Plotter - MARGEN_PLOTTER + ANCHO_DIVISOR_PANTALLA + 5, y0Plotter - MARGEN_PLOTTER, anchoPlotter + 2 * MARGEN_PLOTTER - ANCHO_DIVISOR_PANTALLA - 5, altoPlotter + 2 * MARGEN_PLOTTER);
}

void pintaFolioPlotter() {
  fill(blanco);
  strokeWeight(2);
  stroke(negro);
  rect(x0Plotter, y0Plotter, anchoPlotter, altoPlotter);
}

void pintarBarrasPlotter(int x, int y, boolean lapiz) {
  int sobresale = 10;
  stroke(negro);
  strokeWeight(2);        
  fill(colorBarra);
  rect(x - ANCHO_BARRA_PLOTTER / 2, y0Plotter - sobresale, ANCHO_BARRA_PLOTTER, altoPlotter + 2 * sobresale);
  rect(x0Plotter - sobresale, y - ANCHO_BARRA_PLOTTER / 2, anchoPlotter + 2 * sobresale, ANCHO_BARRA_PLOTTER);
  if (lapiz) {
    fill(rojo);
    ellipse(x, y, 2 * ANCHO_BARRA_PLOTTER, 2 * ANCHO_BARRA_PLOTTER);
  }
}

Dibujo parseaDibujo(JSONObject json) {
  boolean vertical = json.isNull("vertical") ? true : json.getBoolean("vertical");
  String autor = json.isNull("autor") ? "" : json.getString("autor");
  JSONArray curvas = json.isNull("curvas") ? new JSONArray(): json.getJSONArray("curvas");
  long id = json.isNull("id") ? -1 : json.getLong("id");
  return new Dibujo(parseaCurvas(curvas, vertical), vertical, autor, id);
}

ArrayList<Curva> parseaCurvas(JSONArray jsonArray, boolean vertical) {
  ArrayList<Curva> curvas = new ArrayList<Curva>();
  float x = 0;
  float y =  vertical ? 0 : 1;
  for (int j = 0; j < jsonArray.size(); j++) {
    long id = jsonArray.getJSONObject(j).getLong("id");
    JSONArray puntos = jsonArray.getJSONObject(j).getJSONArray("puntos");
    ArrayList<PuntoPorcentaje> puntosTransicion = new ArrayList<PuntoPorcentaje>();
    ArrayList<PuntoPorcentaje> puntosCurva = parseaPuntos(puntos);
    puntosTransicion.add(new PuntoPorcentaje(x, y));
    puntosTransicion.add(new PuntoPorcentaje(puntosCurva.get(0).x, puntosCurva.get(0).y));  
    x = puntosCurva.get(puntosCurva.size() - 1).x;
    y = puntosCurva.get(puntosCurva.size() - 1).y;
    Curva curvaTransicion = new Curva(-1, puntosTransicion, vertical, false);
    Curva trazo = new Curva(id, puntosCurva, vertical);
    curvas.add(curvaTransicion);
    curvas.add(trazo);
  }
  if (!curvas.isEmpty()) {
    ArrayList<PuntoPorcentaje> puntosTransicion = new ArrayList<PuntoPorcentaje>();
    puntosTransicion.add(new PuntoPorcentaje(x, y));
    puntosTransicion.add(new PuntoPorcentaje(0, vertical ? 0 : 1));  
    curvas.add(new Curva(-1, puntosTransicion, vertical, false));
  }
  return curvas;
}

ArrayList<PuntoPorcentaje> parseaPuntos(JSONArray jsonArray) {
  ArrayList<PuntoPorcentaje> puntos = new ArrayList<PuntoPorcentaje>();
  for (int j = 0; j < jsonArray.size(); j++) {
    float x = jsonArray.getJSONObject(j).getFloat("x");
    float y = jsonArray.getJSONObject(j).getFloat("y");
    puntos.add(new PuntoPorcentaje(x, y));
  }
  return puntos;
}

class Dibujo {

  final long id;
  final String autor;
  ArrayList<Curva> curvas;
  final boolean vertical;

  Dibujo(ArrayList<Curva> curvas, boolean vertical, String autor, long id) {
    this.curvas = curvas;
    this.vertical = vertical;
    this.autor = autor;
    this.id = id;
  }
}

class Curva {

  // la verdad que la id sobra...
  final long id;

  boolean pintable = true;

  // para pintar el dibujo en pantalla
  ArrayList<Punto> puntosPixeles = new ArrayList<Punto>();

  // para pintar el dibujo en papel
  ArrayList<Punto> puntosPasos = new ArrayList<Punto>();

  Curva (long id, ArrayList<PuntoPorcentaje> puntosPorcentajes, boolean vertical, boolean pintable) {
    this(id, puntosPorcentajes, vertical);
    this.pintable = pintable;
  }

  Curva(long id, ArrayList<PuntoPorcentaje> puntosPorcentajes, boolean vertical) {
    this.id = id;
    if (puntosPorcentajes.size() == 1) {      
      int x = vertical
        ? (int) (x0Plotter + puntosPorcentajes.get(0).x * anchoPlotter)
        : (int) (x0Plotter + anchoPlotter - puntosPorcentajes.get(0).y * anchoPlotter);
      int y = vertical
        ? (int) (y0Plotter + puntosPorcentajes.get(0).y * altoPlotter)
        : (int) (y0Plotter + puntosPorcentajes.get(0).x * altoPlotter);
      puntosPixeles.add(new Punto(x, y));
    }
    for (int i = 1; i < puntosPorcentajes.size(); i++) {
      int x0 = vertical
        ? (int) (x0Plotter + puntosPorcentajes.get(i - 1).x * anchoPlotter)
        : (int) (x0Plotter + anchoPlotter - puntosPorcentajes.get(i - 1).y * anchoPlotter);
      int y0 = vertical
        ? (int) (y0Plotter + puntosPorcentajes.get(i - 1).y * altoPlotter)
        : (int) (y0Plotter + puntosPorcentajes.get(i - 1).x * altoPlotter);
      int x1 = vertical
        ? (int) (x0Plotter + puntosPorcentajes.get(i).x * anchoPlotter)
        : (int) (x0Plotter + anchoPlotter - puntosPorcentajes.get(i).y * anchoPlotter);
      int y1 = vertical
        ? (int) (y0Plotter + puntosPorcentajes.get(i).y * altoPlotter)
        : (int) (y0Plotter + puntosPorcentajes.get(i).x * altoPlotter);
      puntosPixeles.addAll(bresenham(x0, y0, x1, y1));
    }
  }
}

class Punto {
  final int x, y;
  boolean visible;

  Punto(int x, int y) {
    this.x = x;
    this.y = y;
  }
}

class PuntoPorcentaje {
  float x, y;

  PuntoPorcentaje(float x, float y) {
    this.x = x;
    this.y = y;
  }
}

/**
 modificado de:
 https://rosettacode.org/wiki/Bitmap/Bresenham%27s_line_algorithm#Java
 */
ArrayList<Punto>  bresenham(int x1, int y1, int x2, int y2) {
  ArrayList<Punto> recta = new ArrayList<Punto>();
  int d = 0;
  int dx = Math.abs(x2 - x1);
  int dy = Math.abs(y2 - y1);
  int dx2 = 2 * dx;
  int dy2 = 2 * dy;
  int ix = x1 < x2 ? 1 : -1;
  int iy = y1 < y2 ? 1 : -1;
  int x = x1;
  int y = y1;
  if (dx >= dy) {
    while (true) {
      recta.add(new Punto(x, y));
      if (x == x2)
        break;
      x += ix;
      d += dy2;
      if (d > dx) {
        y += iy;
        d -= dx2;
      }
    }
  } else {
    while (true) {
      recta.add(new Punto(x, y));
      if (y == y2)
        break;
      y += iy;
      d += dx2;
      if (d > dy) {
        x += ix;
        d -= dy2;
      }
    }
  }
  return recta;
}
