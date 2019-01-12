/**
 * modificado de:
 * https://rosettacode.org/wiki/Bitmap/Bresenham%27s_line_algorithm#Java
 */
ArrayList<Punto> bresenham(Punto p1, Punto p2) {
  ArrayList<Punto> recta = new ArrayList<Punto>();
  int d = 0;
  int dx = abs(p2.x - p1.x);
  int dy = abs(p2.y - p1.y);
  int dx2 = 2 * dx;
  int dy2 = 2 * dy;
  int ix = p1.x < p2.x ? 1 : -1;
  int iy = p1.y < p2.y ? 1 : -1;
  int x = p1.x;
  int y = p1.y;
  if (dx >= dy) {
    while (true) {
      recta.add(new Punto(x, y));
      if (x == p2.x)
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
      if (y == p2.y)
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

String fecha() {
  return year() 
    + anyadeCeros(month())
    + anyadeCeros(day())
    + anyadeCeros(hour())
    + anyadeCeros(minute())
    + anyadeCeros(second());
}

String nombreDibujo() {
  return "/data/Dibujos/" + fecha() + ".json";
}

String nombreSVG() {
  return "/data/TSPArt/" + fecha() + ".svg";
}

String anyadeCeros(int i) {
  String out = "" + i;
  while (out.length() < 2) {
    out = "0" + out;
  }
  return out;
}

ArrayList<Punto> rutaDibujo(ArrayList<PuntoRelativo> puntosRelativos, int x0, int y0, int ancho, int alto, boolean vertical) {
  ArrayList<Punto> salida = new ArrayList<Punto>();
  if (puntosRelativos.size() == 1) {  
    PuntoRelativo puntoRelativo = puntosRelativos.get(0);
    int x = vertical
      ? (int) (x0 + puntoRelativo.x * ancho)
      : (int) (x0 + ancho - puntoRelativo.y * ancho);
    int y = vertical
      ? (int) (y0 + puntoRelativo.y * alto)
      : (int) (y0 + puntoRelativo.x * alto);
    salida.add(new Punto(x, y));
  }
  for (int i = 1; i < puntosRelativos.size(); i++) {
    PuntoRelativo puntoRelativo0 = puntosRelativos.get(i - 1);
    PuntoRelativo puntoRelativo1 = puntosRelativos.get(i);
    int p0X = vertical
      ? (int) (x0 + puntoRelativo0.x * ancho)
      : (int) (x0 + ancho - puntoRelativo0.y * ancho);
    int p0Y = vertical
      ? (int) (y0 + puntoRelativo0.y * alto)
      : (int) (y0 + puntoRelativo0.x * alto);
    int p1X = vertical
      ? (int) (x0 + puntoRelativo1.x * ancho)
      : (int) (x0 + ancho - puntoRelativo1.y * ancho);
    int p1Y = vertical
      ? (int) (y0 + puntoRelativo1.y * alto)
      : (int) (y0 + puntoRelativo1.x * alto);
    salida.addAll(bresenham(new Punto(p0X, p0Y), new Punto(p1X, p1Y)));
  }
  return salida;
}

void textoConSombra(String s, float x, float y) {
  fill(NEGRO);
  text(s, x, y + textAscent() / 15);
  fill(#e0dfdc);
  text(s, x, y);
}

void pintarTextoCentro() {
  String s1 = "PROYECTO PLOTTER";
  String s2 ="- INFORMÁTICA AUDIOVISUAL 2018/19 -";
  int y = height / 3;
  int i = 1;
  textSize(i);
  while (textWidth(s1) < (2 * width / 3) * 0.8) {
    i++;
    textSize(i);
  }
  textoConSombra(s1, width / 3 - textWidth(s1) / 2, y); 
  y += textAscent() +  textDescent();  
  i = 1;
  textSize(i);
  while (textWidth(s2) < (2 * width / 3) * 0.8) {
    i++;
    textSize(i);
  }
  textoConSombra(s2, width / 3 - textWidth(s2) / 2, y);
}

boolean tocaPintarTexto;

void controlTextoSimulacion() {
  while (true) {
    tocaPintarTexto = indicePintado != -1 && !dibujoCompleto ? !tocaPintarTexto : false;
    delay(1000);
  }
}

void pintaTextoSimulacion() {
  if (!tocaPintarTexto) {
    return;
  }
  String s3 = "Simulación";
  int i, y;
  i = 1;
  textSize(i);
  while (textWidth(s3) < width / 3 * 0.4) {
    i++;
    textSize(i);
  }
  y = y0PlotterSimulado / 2 + (int) textAscent() / 2;
  textoConSombra(s3, width - width / 6 - textWidth(s3) / 2, y);
}

void pintaTextoVelocidad() {
  String s4 = (pausaPintandoSimulador == 0 ? "∞" : ((int)map(pausaPintandoSimulador, MIN_PAUSA, MAX_PAUSA, MAX_PAUSA + 1, MIN_PAUSA + 1))) + "x";
  textSize((width / 3) / 30);
  int y = height - y0PlotterSimulado / 2 + (int) textAscent() / 2;
  textoConSombra(s4, width - width / 6 - textWidth(s4) / 2, y);
}

void pintaImagenBeta() {
  PImage beta = loadImage("beta.png");
  PImage betaNegro = beta.copy();
  betaNegro.filter(THRESHOLD, 5);
  float wb = beta.width;
  float hb = beta.height;
  float w = width / 4;
  float h = w * hb / wb;
  image(betaNegro, width / 3 - w / 2, height - 2 * h + h / 15, w, h);
  image(beta, width / 3 - w / 2, height - 2 * h, w, h);
}
