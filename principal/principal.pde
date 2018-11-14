// url del servicio rest de donde se descargan los dibujos
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

// hay nuevos dibujos recién cargados
boolean nuevoDibujo;

// medidas

// sección de la simulación del plotter en la pantalla
final int MARGEN_PLOTTER = 100;
int x0Plotter, y0Plotter, anchoPlotter, altoPlotter;

void setup() {
  fullScreen();
  //size(500, 707);
  background(colorFondo);
  stroke(negro);
  thread("cargaNuevosDibujos");
  
  // división de la pantalla
  strokeWeight(2);
  rect(width - width / 3, MARGEN_PLOTTER, 10, height - 2 * MARGEN_PLOTTER);
  
  // medidas del plotter simulado en pantalla
  x0Plotter = width -  width / 3 + MARGEN_PLOTTER;
  anchoPlotter = width / 3 - 2 * MARGEN_PLOTTER;
  altoPlotter = (int) (sqrt(2) * anchoPlotter);
  y0Plotter = height / 2 - altoPlotter / 2;
}

void draw() {
  if (nuevoDibujo) {
    nuevoDibujo = false;
    indicePintado = dibujos.size() - 1;
    dibujar(dibujos.get(indicePintado));
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
    dibujar(dibujos.get(indicePintado));
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

void dibujar(Dibujo dibujo) {
  //println("dibujando:\t" + dibujo.id);
  fill(blanco);
  strokeWeight(2);
  rect(x0Plotter, y0Plotter, anchoPlotter, altoPlotter);
  strokeWeight(5);
  for (Curva curva : dibujo.curvas) {
    if (curva.puntos.size() == 1) {
      pintaLinea(curva.puntos.get(0), curva.puntos.get(0), true);
    }
    for (int i = 1; i < curva.puntos.size(); i++) {
      pintaLinea(curva.puntos.get(i - 1), curva.puntos.get(i), dibujo.vertical);
    }
  }
}

void pintaLinea(Punto p0, Punto p1, boolean vertical) {
  float x0, y0, x1, y1;
  if (vertical) {
    x0 = x0Plotter + p0.x * anchoPlotter;
    y0 = y0Plotter + p0.y * altoPlotter;
    x1 = x0Plotter + p1.x * anchoPlotter;
    y1 = y0Plotter + p1.y * altoPlotter;
  } else {
    // se invierten
    x0 = x0Plotter + anchoPlotter - p0.y * anchoPlotter;
    y0 = y0Plotter + p0.x * altoPlotter;
    x1 = x0Plotter + anchoPlotter - p1.y * anchoPlotter;
    y1 = y0Plotter + p1.x * altoPlotter;
  }
  line(x0, y0, x1, y1);
}

Dibujo parseaDibujo(JSONObject json) {
  boolean vertical = json.isNull("vertical") ? true : json.getBoolean("vertical");
  String autor = json.isNull("autor") ? "" : json.getString("autor");
  JSONArray curvas = json.isNull("curvas") ? new JSONArray(): json.getJSONArray("curvas");
  long id = json.isNull("id") ? -1 : json.getLong("id");
  return new Dibujo(parseaCurvas(curvas), vertical, autor, id);
}

ArrayList<Curva> parseaCurvas(JSONArray jsonArray) {
  ArrayList<Curva> curvas = new ArrayList<Curva>();
  for (int j = 0; j < jsonArray.size(); j++) {
    long id = jsonArray.getJSONObject(j).getLong("id");
    JSONArray puntos = jsonArray.getJSONObject(j).getJSONArray("puntos");
    curvas.add(new Curva(id, parseaPuntos(puntos)));
  }
  return curvas;
}

ArrayList<Punto> parseaPuntos(JSONArray jsonArray) {
  ArrayList<Punto> puntos = new ArrayList<Punto>();
  for (int j = 0; j < jsonArray.size(); j++) {
    puntos.add(new Punto(jsonArray.getJSONObject(j).getFloat("x"), jsonArray.getJSONObject(j).getFloat("y")));
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

  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append("autor: " + autor + "; vertical: " + vertical + "; curvas: {");
    for (Curva curva : curvas) {
      sb.append(curva + ", ") ;
    }
    if (curvas.size() > 0) {
      sb.deleteCharAt(sb.length() - 1); 
      sb.deleteCharAt(sb.length() - 1);
    }
    sb.append("}");
    return sb.toString();
  }
}

class Curva { 

  final long id;
  ArrayList<Punto> puntos;

  Curva(long id, ArrayList<Punto> puntos) {
    this.id = id;
    this.puntos = puntos;
  }

  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append("id: " + id + "; puntos: {");
    for (Punto punto : puntos) {
      sb.append(punto + ", ");
    }
    if (puntos.size() > 0) {
      sb.deleteCharAt(sb.length() - 1); 
      sb.deleteCharAt(sb.length() - 1);
    }
    sb.append("}");
    return sb.toString();
  }
}

class Punto {

  final float x, y;

  Punto(float x, float y) {
    this.x = x;
    this.y = y;
  }

  public String toString() {
    return "(" + x + ", " + y + ")";
  }
}
