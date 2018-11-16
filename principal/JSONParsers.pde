/**
 Métodos que reciben objetos JSONObjet o JSONArray y
 retornan objetos de las clases Java del modelo
 */

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
    curvas.add(new Curva(-1, puntosTransicion, vertical, false));
    curvas.add(new Curva(id, puntosCurva, vertical));
    x = puntosCurva.get(puntosCurva.size() - 1).x;
    y = puntosCurva.get(puntosCurva.size() - 1).y;
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
