/**! -*- Mode: Java; c-basic-offset: 4 -*-
 *
 * Copyright (c) 1999 by Rasmus Sten <rasmus@sno.pp.se>
 *
 */
package nu.dll.lyskom;

/**
 * Thrown by the Selection class when an application tries to access a
 * non-existant key.
 */
public class NoSuchKeyException extends RuntimeException {
	private static final long serialVersionUID = 9039238526949947507L;
	public NoSuchKeyException() {
		super();
	}
	public NoSuchKeyException(String s) {
		super(s);
	}
}
