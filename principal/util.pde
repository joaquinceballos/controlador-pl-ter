/**
 modificado de:
 https://rosettacode.org/wiki/Bitmap/Bresenham%27s_line_algorithm#Java
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
