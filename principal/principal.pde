// url del servicio rest de donde se descargan los dibujos
final String URL = "http://plotter.ddns.net:82";

// frecuancia de consulta por nuevos dibujos
final long FRECUENCIA_CONSULTA = 5000;

// tiempo de la última carga de dibujos
long tUltimaCarga;

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

void setup() {
  size(500, 707);
  background(colorFondo);
  stroke(negro);
  strokeWeight(5);
  thread("cargaNuevosDibujos");
}

void draw() {
  if (millis() - tUltimaCarga > FRECUENCIA_CONSULTA && !hiloTrabajando) {
    thread("cargaNuevosDibujos");
  }
  if (indicePintado == -1 && !dibujos.isEmpty()) {
    indicePintado = 0;
    dibujar(dibujos.get(0));
  }
}

/**
 provisional
 */
void keyPressed() {
  if (dibujos.size() > 0 && (keyCode == RIGHT || keyCode == LEFT)) {
    background(colorFondo);
    if (keyCode == LEFT) {
      indicePintado = indicePintado == 0 ? dibujos.size() - 1 : indicePintado - 1;
    } else {      
      indicePintado = indicePintado == dibujos.size() - 1  ? 0 : indicePintado + 1;
    }
    dibujar(dibujos.get(indicePintado));
  }
}

void cargaNuevosDibujos() {
  hiloTrabajando = true;
  JSONArray jsonArray = loadJSONArray(URL + "/dibujo/descargar" + (ultimaId == -1 ? "" : "?last=" + (ultimaId)));
  for (int i = 0; i < jsonArray.size(); i++) {    
    JSONObject dibujo = jsonArray.getJSONObject(i);
    ultimaId = dibujo.getInt("id");
    dibujos.add(parseaDibujo(dibujo));
  }
  tUltimaCarga = millis();
  hiloTrabajando = false;
}

void dibujar(Dibujo dibujo) {
  for (Curva curva : dibujo.curvas) {
    if (curva.puntos.size() == 1) {
      pintaLinea(curva.puntos.get(0), curva.puntos.get(0), dibujo.vertical);
    }
    for (int i = 1; i < curva.puntos.size(); i++) {
      pintaLinea(curva.puntos.get(i - 1), curva.puntos.get(i), dibujo.vertical);
    }
  }
}

void pintaLinea(Punto p0, Punto p1, boolean vertical) {
  float x0, y0, x1, y1;
  if (vertical) {
    x0 = p0.x * width;
    y0 = p0.y * height;
    x1 = p1.x * width;
    y1 = p1.y * height;
  } else {
    // se invierten
    x0 = width - p0.y * width;
    y0 = p0.x * height;
    x1 = width - p1.y * width;
    y1 = p1.x * height;
  }
  line(x0, y0, x1, y1);
}

Dibujo parseaDibujo(JSONObject json) {
  boolean vertical = json.getBoolean("vertical");
  String autor = json.getString("autor");
  JSONArray curvas = json.getJSONArray("curvas");
  long id = json.getLong("id");
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
