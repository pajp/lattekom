package nu.dll.lyskom;

import java.util.StringTokenizer;

public class LocationAuxItem extends AuxItem {
    double longitude;
    double latitude;
    double accuracy;
    public LocationAuxItem(int tag, double latitude, double longitude, double accuracy) {
	super(tag, latitude + " " + longitude + (accuracy != -1 ? " " + accuracy : ""));
	this.latitude = latitude;
	this.longitude = longitude;
	this.accuracy = accuracy;
    }
    public LocationAuxItem(int tag, double latitude, double longitude) {
	this(tag, latitude, longitude, -1);
    }

    public LocationAuxItem(int tag, String s) {
	super(tag, s);
	try {
	    StringTokenizer st = new StringTokenizer(s);
	    String latstr = st.nextToken();
	    String longstr = st.nextToken();
	    String accstr = null;
	    if (st.hasMoreTokens()) accstr = st.nextToken();
	    latitude = Double.parseDouble(latstr);
	    longitude = Double.parseDouble(longstr);
	    if (accstr != null) accuracy = Double.parseDouble(accstr);
	} catch (NumberFormatException ex1) {
	    throw new RuntimeException("Malformed location aux-item: " + s);
	}
    }

    public double getLatitude() {
	return latitude;
    }

    public double getLongitude() {
	return longitude;
    }

    public double getAccuracy() {
	return accuracy;
    }

}