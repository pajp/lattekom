<%@ page language='java' import='nu.dll.lyskom.*' %>
<%@ page pageEncoding='iso-8859-1' contentType='text/html; charset=utf-8' %>
<%@ include file='kom.jsp' %>
<%!
    static class TextTreeNode {
	public TextStat textStat;
	public List comments;
	public TextTreeNode(TextStat ts) {
	    this.textStat = ts;

	    comments = new LinkedList();
	}
    }

    void printNode(StringBuffer buf, Session lyskom, Map nodes, List texts, int textNumber, List textsToView, int depth) throws Exception {
	texts.remove(new Integer(textNumber));
	TextTreeNode node = (TextTreeNode) nodes.get(new Integer(textNumber));
	textsToView.add(new Integer(textNumber));
	if (depth == 0) {
	    buf.append("<br/><i>");
            Text text = lyskom.getText(textNumber);
	    String charset = text.getCharset();
	    if ("us-ascii".equals(charset)) charset = "iso-8859-1";

	    buf.append(htmlize(new String(text.getSubject(), charset)));
	    buf.append("</i><br/>\n");
	}
	String authorName = lookupName(lyskom, node.textStat.getAuthor(), false);
	String authorNameStripped = authorName.replaceAll(" *\\(.*?\\) *", "").trim();
	buf.append("<img src=\"bullet_unsel.gif\" id=\"bullet_" + textNumber + "\" />");
	buf.append("<tt>");
	for (int i=0; i < depth; i++) 
	    buf.append("&nbsp;&nbsp;");
	buf.append("</tt>");
	buf.append("<a onClick=\"selectText(" + textNumber + ");\" title=\"" + textNumber + " av " + htmlize(authorName) + "\" href=\"�LINK�#text" + textNumber + "\" target=\"textViewFrame\">");
	buf.append(htmlize(authorNameStripped));
	buf.append("</a>");
	buf.append("<br/>\n");
	//buf.append("<span title=\"" + node.textStat.getNo() + "\">*</span>\n");
	if (node.comments.size() > 0) {
            for (Iterator i = node.comments.iterator(); i.hasNext();) {
		TextTreeNode commentNode = (TextTreeNode) i.next();
		printNode(buf, lyskom, nodes, texts, commentNode.textStat.getNo(), textsToView, depth+1);
	    }
	}
    }
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
  <head>
    <title>Tr�dvy</title>
    <link rel="stylesheet" href="lattekom.css" />
  </head>
  <script language="JavaScript1.2">
    var selected = null;
    function selectText(textNo) {
	if (selected != null) {
	    var simg = document.getElementById("bullet_" + selected);
	    if (typeof(simg) != "undefined") {
		simg.src = "bullet_unsel.gif";
	    }
	}
	var nimg = document.getElementById("bullet_" + textNo);
	if (typeof(nimg) != "undefined") {
	    nimg.src = "bullet_sel.gif";
	    selected = textNo;
	}
    }
  </script>
  <body class="treeView">

<%
    Session lyskom = (Session) session.getAttribute("lyskom");
    if (lyskom == null || !lyskom.getConnected() || !lyskom.getLoggedIn()) {
	response.sendRedirect("/lyskom/");
	return;
    }

    int conferenceNumber = 0;
    try {
	conferenceNumber = Integer.parseInt(request.getParameter("conference"));
    } catch (NumberFormatException ex1) {}

    if (conferenceNumber > 0) {
	Membership membership = lyskom.queryReadTextsCached(conferenceNumber);
	UConference uconf = lyskom.getUConfStat(conferenceNumber);
	TextMapping mapping = uconf.getHighestLocalNo() > membership.getLastTextRead() ?
		lyskom.localToGlobal(conferenceNumber, membership.getLastTextRead()+1, 100) : null;
	Map nodes = new HashMap();
	List texts = new LinkedList();
	Set seen = new HashSet();
	List textsToView = new LinkedList();
	while (mapping != null &&mapping.hasMoreElements()) {
	    int textNo = ((Integer) mapping.nextElement()).intValue();
	    TextStat ts;
	    try {
		ts = lyskom.getTextStat(textNo);
	    } catch (RpcFailure ex1) {
		if (ex1.getError() == Rpc.E_no_such_text) {
		    continue;
		} else {
		    throw ex1;
		}
	    }
	    TextTreeNode node = new TextTreeNode(ts);
	    nodes.put(new Integer(textNo), node);
	    if (!texts.contains(new Integer(textNo)) && !seen.contains(new Integer(textNo)))
		texts.add(new Integer(textNo));
	    seen.add(new Integer(textNo));
	    int[] comments = node.textStat.getStatInts(TextStat.miscCommIn);
	    for (int j=0; j < comments.length; j++) {
		int comment = comments[j];
		TextTreeNode commentNode = (TextTreeNode) nodes.get(new Integer(comment));
		if (commentNode == null) {
		    try {
		        commentNode = new TextTreeNode(lyskom.getTextStat(comment));
	    	    } catch (RpcFailure ex1) {
			if (ex1.getError() == Rpc.E_no_such_text) {
		    	    continue;
			} else {
		    	    throw ex1;
			}
	    	    }
		    nodes.put(new Integer(comment), commentNode);
		}
		if (commentNode != null) {
		    node.comments.add(commentNode);
		    seen.add(new Integer(comment));
		}
	    }

	}
	StringBuffer treeHtml = new StringBuffer(1024);
	while (texts.size() > 0) {
	    printNode(treeHtml, lyskom, nodes, texts, ((Integer) texts.remove(0)).intValue(), textsToView, 0);
	}

	StringBuffer linkBuf = new StringBuffer();
	linkBuf.append(basePath);
	linkBuf.append("?hw&hs&conference=").append(conferenceNumber).append("&");
	for (Iterator i=textsToView.iterator(); i.hasNext();) {
	    linkBuf.append("text=" + i.next());
	    if (i.hasNext()) linkBuf.append("&");
	}
	int firstText = textsToView.size() > 0 ? ((Integer) textsToView.get(0)).intValue() : 0;
	String link = linkBuf.toString();
	String html = treeHtml.toString().replaceAll("�LINK�", link);
	out.println(html);
	out.println("<script language=\"JavaScript1.2\">parent.textViewFrame.document.location = \"" +
		link + "#text" + firstText + "\";selectText(" + firstText + ");</script>");
    } else {
		Iterator confIter = new LinkedList(lyskom.getUnreadConfsListCached()).iterator();
		int sum = 0, confsum = 0;
		while (confIter.hasNext()) {
		    int conf = ((Integer) confIter.next()).intValue();
		    Membership membership = lyskom.queryReadTextsCached(conf);
		    UConference uconf = lyskom.getUConfStat(conf);
		    int unreads = 0;
		    if (uconf.getHighestLocalNo() > membership.getLastTextRead()) {
			unreads = uconf.getHighestLocalNo() -
				membership.getLastTextRead();
		    }
		    if (unreads == 0) continue;
		    sum += unreads;
		    confsum++;
		    out.print("<a target=\"_top\" href=\"" + basePath + "frames.jsp?conference=" +
				conf + "\">" + 
				lookupName(lyskom, conf, true) + "</a>: " +
				unreads + "<br/>");
		}
	out.println("<script language=\"JavaScript1.2\">parent.textViewFrame.document.location = \"" +
		basePath + "\";</script>");
    }
%>
  <p>
  >> <a href="tree.jsp?conference=<%=conferenceNumber%>">uppdatera</a><br/>
  >> <a target="_top" href="frames.jsp?conference=0">nyheter</a><br/>
  >> <a href="<%=basePath%>" target="_top">Till huvudsidan</a><br/>
  </p>
  </body>
</html>