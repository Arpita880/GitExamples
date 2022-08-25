<%@ page language="java" import="com.qwest.websop.*, java.util.*, java.io.*,com.qwest.serviceform.*" 
	import="com.qwest.websop.find.FindData"
	session="false" %> 
<%@ page buffer="12kb" autoFlush="true" %>
<%@ page errorPage="Error.jsp" %>
<%
	WebsopHandlerGetCSR handler = 
			(WebsopHandlerGetCSR) request.getAttribute("handler");
	WebsopSession websop = handler.getWebsopSession();
	String state = handler.getState();
    String winName=websop.getWinName();
    
    String csrHeaderHtml = handler.getCsrHeaderHtml();
    String csrBodyHtml = handler.getCsrBodyHtml();

   	// parameters for css theme.
   	UserThemeElement elem = websop.curTheme;
   	if (elem == null) {
     	elem = websop.getUserSession().getDefaultTheme();
   	}
  	// end of theme parameter
  	
	ServiceRecord sf = (ServiceRecord) websop.getWebsopUtility();
    String type=sf.getHeaderFidValue("TYPE");
	String viewtype=sf.getHeaderFidValue("VIEW");
	String dd=sf.getHeaderFidValue("VD");
	
   	// Shouldn't this be always ""??? it seems used as an indicator
   	// for entry from Main menu or Account selection screen
    String statusmsg = (String)request.getAttribute("statusmsg");
    String action = handler.action;
	
    //find usoc/fid
	UserPrefElement upelem = websop.getUserSession().getUserPrefElement();
   	int numberOfLines = WebsopSession.getWlines(upelem);
	ServiceFormPage sfp=sf.getPage();
   	
    int fileBodyLength = sf.getFileLength();
    String tn = WebsopUtil.findTN(sf,websop);
    String cusCode = sf.getCUS();
    String suf = sf.getSUF();
    String csr_region = WebsopUtil.getSOPRegion(websop.getTN());

    int pageEndLine = sfp.getEndLine();
    int pageStartLine = 0;
    if (pageEndLine>0)
        pageStartLine = sf.getLineNumFromPageHide(websop.getStartLine(), numberOfLines);

    FindData findData = handler.getFindData();
    
   // set screenLeft/Top based on request
   String requestScreenLeft = request.getParameter("screenLeft");
   if(requestScreenLeft == null)
   		requestScreenLeft = "";
   String requestScreenTop = request.getParameter("screenTop");
   if(requestScreenTop == null)
   		requestScreenTop = "";
   	  
   boolean insearch = websop.isInWsearch();
   String foundInd;
   String findMsg = findData.getFindMsg();
   if (insearch == true) {
	   	if (findMsg != null && findMsg.equals("No matches found!")) {
	   		foundInd = "0";
	   		findData.setFindMsg(null);  
	   	} else {
	   		foundInd = "1";
	   	}
	   	websop.setInWsearch(false);
   } else {
	    //not insearch
	   	foundInd = "-1";
	    findData.resetRequestSearchtext();
   }
  
  // end of find parameters   
    
	UserElement ue = websop.getUserSession().getUserElement();

	NoteCsrDO noteCsrDO = WebsopHandler.populateAutoNote(ue, upelem); 
  	String notePrepend = noteCsrDO.getNotePrepend();
  	String noteType = noteCsrDO.getNoteType();
  	String noteType2 = noteCsrDO.getNoteType2();
  
  	websop.setCsrTn("");
    String vFontSize;
    if (elem != null)
        vFontSize = elem.getFontSize();
    else
        vFontSize = "14";
	handler.initLineSize(vFontSize);

  	double lineHeight = handler.getLineHeight();
    int divHeight = handler.getDivHeight();
      
  	String scrollCsr = (String)request.getAttribute("csrScrollTop");
  	int scrollToSec = handler.getCsrDisplayLine();
	String stcd = sf.getHeaderFidValue("STCD");
   
   //Expand the definition to VCSR status codes that begin with "SNP" or "SUS".
   //Expand the definition to disconnected account VCSR statuses of "ZDIS" and "RDIS"	
   //Expand the definition to final  account VCSR statuses of "ZFIN
   
   if (stcd.equals("DISC") || stcd.equals("ZDIS") || stcd.equals("RDIS") || stcd.equals("ZFIN") || stcd.startsWith("FIN")
  			|| stcd.equals("RFIN") || stcd.startsWith("SNP") || stcd.startsWith("SUS")) 
	{
		request.setAttribute("confirmmsg",
  		 "CSR status is " + stcd + ", do you still want to issue an order?");
  		}
  
	boolean hasStn = sf.isMan();
	String errDemandCsr = (String)request.getAttribute("DCSRerrmsg");
	boolean isDemandCSR = false;

	if (suf!=null && suf.equals("DMD"))
		isDemandCSR = true;
	String popupConsDialog = (String)request.getAttribute("popupConsDialog");
	String ac = (String)request.getAttribute("consolidateAC");
	String acElem = (String)request.getAttribute("popupConsElem");
	if(acElem==null)
		acElem = IWSOP.emptyString;
	String consErr = (String)request.getAttribute("consErr");
	if(consErr==null)
		consErr = IWSOP.emptyString;
	String consDD = (String)request.getAttribute("consDD");
	String consED = (String)request.getAttribute("consED");
	if(consDD==null)
		consDD = IWSOP.emptyString;
	if(consED==null)
		consED = IWSOP.emptyString;	
%>
<HTML>
<HEAD>
<SCRIPT LANGUAGE="JavaScript" type="text/javascript">

	var closesWindow = false;
	var running = "false";

	var tr = null;
 
	function processJumpSec(obj) {
     	var val = obj.options[obj.selectedIndex].value; 
     	document.form1.startLineNum.value =val;
     	document.form1.act.value = "JUMPSEC";
     	doAction();
 	}

	function processHide(img, act) {
   		document.form1.hideline.value = img.name;
   		document.form1.act.value = act;
   		document.form1.startLineNum.value=<%=websop.getStartLine()%>;
	}

   
	function checkDD() {
	 	var dd = document.form1.duedate.value;
	 	var pattern1= /\d\d-\d\d-\d\d\d\d/;
	 	var pattern2=/\d\d\/\d\d\/\d\d\d\d/;
	 
	 	// TODO: Double check this.  Is this correct?
	 	if (dd == null)
	     	dd="";
	     
	 	if (dd.length!=0) {
		 	if (dd.length <10) {
		 		alert("Date Format should be MM-DD-YYYY or MM/DD/YYYY");
		 		enableButtons();
		 		return false;
	 		} else {
		 		var result1 = dd.match(pattern1);
		 		var result2 = dd.match(pattern2);
		 		if (result1==null && result2==null) {
			 		alert("Date Format should be MM-DD-YYYY or MM/DD/YYYY");
			 		enableButtons();
			 		return false;
				}
	 		}
 		}
 		return true;
	}

	function processBack(act){
     	if (running=="true") {
         	return false;
     	}
     	document.form1.act.value = act;
     	doAction();
 	}

	function processForm1(act, lineNum){
     	if (running=="true") {
         	return false;
     	}

     	document.form1.act.value = act;

     	if( act == "<%=IWSOP.A_UPDATE%>" ){
         	document.form1.state.value = "MainMenu";
     	} else if(act == "IMAGEACTION"){
         	document.form1.act.value = act;
         	document.form1.startLineNum.value =lineNum;
     	} else if (act == "SEARCH") {
         	document.form1.startLineNum.value =lineNum;
         	doAction();   
     	} else if (act == "SEARCHPREV") {
         	document.form1.startLineNum.value =lineNum;   
         	doAction();     
     	} else if(act == "QUERY" ){
         	document.form1.target= "_self";
         	if(checkDD())
             	doAction();
     	} else if (act == "JUMP" ) {
         	var bodylines = <%=fileBodyLength%>;
         	document.form1.act.value = act;
         	var jumpline;
         	if(document.form1.jumpline.value == "")
         	{
             	jumpline = lineNum;
         	}else{
             	jumpline = parseInt(document.form1.jumpline.value);
         	}
           
         	if(jumpline<1 || jumpline>bodylines) {
             	alert("NOT A VALID LINE NUMBER! REENTER PLEASE!");
         	} else {
             	document.form1.startLineNum.value =jumpline;
             	doAction();
         	}
    	} else if (act == "REFRESH" )  {
        	document.form1.duedate.value="";
        	doAction();
    	} else if (act == "NOTES") {
	    	document.form1.rp.value = 'INTRA';
	    	var date=new Date();
	    	var newString=date.getHours()+date.getMinutes()+date.getSeconds()+date.getMilliseconds();
    		//var result = showModalDialog("/websop/jsp/NoteCsr.jsp?fromCsrPage=T"+newString+"&winname="+"<%=winName%>", window.self, "status:no; scroll:no; dialogHeight:220px; dialogWidth:600px");
    		 window.open("/websop/jsp/NoteCsr.jsp?fromCsrPage=T"+newString+"&winname="+"<%=winName%>", window.self, "status:no; scroll:no; dialogHeight:220px; dialogWidth:600px");
	
    	} else if (act == "INQCSR"  || act == "MISELECTION") {
        	document.form1.<%=IWSOP.P_INQACCT%>.value = "<%=(tn + cusCode + suf) %>";
        	if(checkDD())
             	doAction();
   		}
 	}

 	function toUpper(event){
    	var charCode = event.keyCode;
    	if(charCode > 96 && charCode < 123) {
         	event.keyCode = charCode - 32;
    	}
 	}
 
	function processJumpLine(act) {
 		if (document.form1.jumpline.value == ""){
        	alert("Please enter only numbers in this field.");
        	return false;
    	} else {
      		processForm1('JUMP', <%=websop.getStartLine()%>);
   		}
 	}

 	function init() {
 		<%@include file="alertCheck.include"%>

		<%if (scrollToSec==1) { %>
   			document.all["divData"].scrollTop = 0;
		<%} else if (scrollToSec!=-1) {%>
   			highlight(<%=scrollToSec%>);
		<%} else if (scrollCsr!=null 
						&& (action!=null 
								&& action.indexOf("REFRESH")<0
								&& action.indexOf("ACCOUNT")<0) )
  		  {%>
    		document.all["divData"].scrollTop = <%=scrollCsr%>;
		<%}%>
    		
        <%if (action.equals(IWSOP.A_DEMANDCSR)&&(errDemandCsr!=null&&!errDemandCsr.trim().equals(""))) {%>
				processDemandCsr();
		<% } %>
		// for find in csr
		var myAction = "<%=action%>";
		if (myAction == 'SEARCH' || myAction == 'SEARCHPREV') {	
   			var screenLeft = document.form1.screenLeft.value + 'px';
   			var screenTop = document.form1.screenTop.value + 'px';
   			var insearch = 1;
   			processFind(myAction, screenLeft, screenTop, insearch );
		}

		//for find usoc/fid
		if (myAction == 'FINDUSOCFID') {	
 			var foundlinenum = document.form1.foundlineno.value;
			if (foundlinenum>0)
				highlight(foundlinenum);   
   
			var screenLeft = document.form1.screenLeft.value + 'px';
			var screenTop = document.form1.screenTop.value + 'px';
			var insearch = 1;
			processFindUsocFid(screenLeft, screenTop, insearch );
		}
		
				
		// popup Consilidate popup dialog.
		<%if(popupConsDialog !=null &&
			(popupConsDialog.equals("CONSD") 
			 || popupConsDialog.equals("DECONS"))) { %>
				popupConsDialog();
		<% } %>
 	}
 
    <% if (popupConsDialog!=null) { %>
    function popupConsDialog() {
    	//while (document.form1.formSubmit.value != "true") {
		 			var ac = '<%=ac%>';
	 				var date=new Date();
		    		var millsec = date.getHours()+date.getMinutes()+date.getSeconds()+date.getMilliseconds();
		 			var url = "/websop/jsp/ConsolidateBilling.jsp?winname=<%=winName%>&consolidateAC=" + ac + 
		 			          "&acElem=" + '<%=acElem%>' + "&consErr=" + '<%=consErr%>' + "&consDD=" + '<%=consDD%>' + 
		 			          "&consED=" + '<%=consED%>' + '&uniqueno=T' + millsec;
	 				var result = showModalDialog(url, window.self,
	 					'status:no; scroll:no; dialogHeight:320px; dialogWidth:<%=popupConsDialog.equals("DECONS")?"450":"850"%>px');
					if (document.form1.formSubmit.value == 'true') {
				       document.form1.act.value = "<%=IWSOP.A_NEW%>";
				       <% if (popupConsDialog.equals("DECONS")) { %>
				       		document.form1.ordertype.value = "MI_ISCNN1006";
				       <% } else { %>
				       		document.form1.ordertype.value = "MI_ICON10011";
				       <% } %>
			    	   doAction();
					}
		//		}
    }
    <% } %>
    
	// find functions
	function processFind(act, screenLeft, screenTop, insearch) {
    	document.form1.act.value = act;

    	// find start from the begin of the page
    	tr = null;
    
    	// check where is called: from menu or between pages.
    	if (insearch == 0)
    		document.form1.searchtext.value = "";
    
    	var features = null;
    	if (screenLeft == null){
    		features = "status:no; scroll:no; dialogHeight:160px; dialogWidth:320px"; 
    	} else {
    		features = "status:no; scroll:no; dialogHeight:160px; dialogWidth:320px; " + "dialogLeft:" + screenLeft + "; dialogTop:" + screenTop;
    	}
    	//var result = showModalDialog("/websop/jsp/find.html", window.self, features);
    	 removeSelection();
     	window.open("/websop/jsp/find.html", "", "scrollbars=yes,resizable=yes,top=400,left=500,width=500,height=400");
	}

	//Duplicated in ViewOrder.jsp
	/*function findString(fromStr, currentField) {
		//alert("call findString()");
		if (tr == null){
			tr = document.body.createTextRange( );
			tr.findText("STATUS");	//move to the begining of the order. 
		}
		else
			tr.moveStart("character");
	
		// starting searching ...
		if(tr.findText(fromStr)){
			tr.select();
			return 0;
		} else {
			// end of body
			tr = null;
			return -1;
		}
	}*/

	//Duplicated in ViewOrder.jsp	
	//for find previous
	/*function findStringPrev(fromStr) {
		if (tr == null) {
			tr = document.body.createTextRange( );
		}
		else
			tr.moveEnd("character", -1);
	
		// starting searching ...
		if (tr.findText(fromStr, -1)){ //search backward
			tr.select();
			return 0;
		} else {
			// end of body
			tr = null;
			return -1;
		}
	}*/



	function findString(fromStr) {
		debugger;
		if (window && window.find) {
			//window.find(aString, aCaseSensitive, aBackwards, aWrapAround, aWholeWord, aSearchInFrames, aShowDialog);
			//var response=window.find(fromStr, false, false, false, false, true, false);
			//var rect =window.getSelection().getRangeAt(0).getBoundingClientRect();
			//document.all["divData"].scrollTop = rect.bottom;
			//return response

			var response=window.find(fromStr, false, false, false, false, true, false);
			var range  = window.getSelection().getRangeAt(0);
			var rect = range.getBoundingClientRect();
			const element = document.createElement("span");
			element.setAttribute('id', 'scrollEl');
			range.surroundContents(element);  
			var rowToScrollTo = document.getElementById('scrollEl');
			rowToScrollTo.scrollIntoView({ behavior: 'smooth', block: 'center' });
			element.setAttribute('id', '');
			return response;
		}
	}

	function findStringPrev(fromStr) {
		debugger;
		if (window && window.find) {
			//window.find(aString, aCaseSensitive, aBackwards, aWrapAround, aWholeWord, aSearchInFrames, aShowDialog);
		
			//var response= window.find(fromStr, false, true, false, false, true, false);
			//var rect =window.getSelection().getRangeAt(0).getBoundingClientRect();
			//document.all["divData"].scrollTop = rect.bottom;
			//return response;

			var response= window.find(fromStr, false, true, false, false, true, false);
			var range = window.getSelection().getRangeAt(0);
			var rect =range.getBoundingClientRect();
			const element = document.createElement("span");
			element.setAttribute('id', 'scrollE2');
			range.surroundContents(element);  
            var rowToScrollTo = document.getElementById('scrollE2');
            rowToScrollTo.scrollIntoView({ behavior: 'smooth', block: 'center' });
			element.setAttribute('id', '');
			//document.all["divData"].scrollTop = rect.height;
			return response;
		}
	}

	 function removeSelection() {
		 
	        var sel = window.getSelection ? window.getSelection() : document.selection;
	      
	        if (sel) {
	            if (sel.removeAllRanges) {
		            sel.removeAllRanges();
	            } else if (sel.empty) {
	           
	                sel.empty();
	            }
	        }
	    }
// end of find functions 





//find usoc/fid
	function processFindUsocFid(screenLeft, screenTop, insearch) {
	    if (running=="true") {
    	    //alert("Websop Running ...");
        	return false;
    	}

		var sectionlist="";
		var sectionname;
		for (var i=1; i < document.form1.section.length; i++) {
			if(document.form1.section.options[i].text=="S&E"){
				sectionname = "sect" + i + "=" + "S" + "%26" + "E" ;   
			}
			else
				sectionname = "sect" + i + "=" + document.form1.section.options[i].text;
			if (sectionlist=="")
				sectionlist = sectionlist + sectionname;
			else
				sectionlist = sectionlist + "&" + sectionname;
		}
		document.form1.act.value = 'FINDUSOCFID';
    
    	var features;
    	if ( screenLeft == null) {
    		features = "status:no; scroll:no; dialogHeight:225px; dialogWidth:730px";
    	} else {
    		features = "status:no; scroll:no; dialogHeight:225px; dialogWidth:730px; " + "dialogLeft:" + screenLeft + "; dialogTop:" + screenTop;
    	}
    	//var result = showModalDialog("/websop/jsp/findUsocFid.jsp?"+sectionlist, window.self, features);
    	window.open("/websop/jsp/findUsocFid.jsp?"+sectionlist, "", "scrollbars=yes,resizable=yes,top=200,left=400,width=800,height=300,bottom=100");
 	}

  	function highlight(lineno) {	
		document.location.href="#" +lineno;
	}
  
//end of find usoc/fid functions
 
  	//select group/section from an account
	function processCheckbox(checkbox) {
		return true;
  	}  
  
  //end of select group/section from an account
  
	function clickOrderLink(ordernum) {
  		document.form1.act.value = "<%=IWSOP.A_INQORD%>";
    	document.form1.inqord.value = ordernum;
    	document.form1.state.value = "GetCSR";
    	doAction();
  	}
  	
  	function checkSubmit() {
    	if (running=="true")
      		return false;
      		
	    disableButtons();
      	return true;
  	} 
  
  	function processDemandCsr() {   
    	var date=new Date();
		var millsec = date.getHours()+date.getMinutes()+date.getSeconds()+date.getMilliseconds();
    	var url = "/websop/jsp/demandCSR.jsp?winname=" + "<%=winName%>" + "&hasStn=" + <%=hasStn%> + "&uniqueno=T"+millsec;
    	//var result = showModalDialog(url, window.self, "status:no; scroll:no; dialogHeight:170px; dialogWidth:400px");
    	window.open(url, window.self, "status:no; scroll:no; dialogHeight:170px; dialogWidth:400px");
  	}
</SCRIPT>
  <script src="/websop/jsp/js/menu.js" type="text/javascript">
  </script>
  <script src="/websop/jsp/js/GUIHelper.js" type="text/javascript">
  </script>
  
    <!-- This crazy bit of code pushes the stock IE window title out of view -->
    <TITLE>CSR <%=sf.getTN() + " (" + sf.getCUS() + ") " + sf.getSUF()%> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
    </TITLE>
  </HEAD>
  
  <body class="htmlPage" onBeforeUnload="if(closesWindow == true) {windowClosedWithX();}" onmouseover="closesWindow=false;" onmouseout="closesWindow=true;" onmousedown="closesWindow=false;" onLoad="init()" onKeyDown="disableEnterKey(event); disableKeys(event)" onKeyUp="handleShortKeys(event)"> 
  
<!-- topMenu needs websop declared and menu.js called -->
<%@ include file="./topMenu.include" %>
<!-- use the common css -->
<%@ include file="./css.include" %>
      <br>
	<FORM name="form1" method="post" action="./controller.jsp" onSubmit="return checkSubmit()">
           <input type="hidden" name="state" value="<%=state%>">
           <input type="hidden" name="ordertype" value="">
           <input type="hidden" name="act" value="">
           <input type="hidden" name="tn" value="<%=tn%>">
           <input type="hidden" name="<%=IWSOP.P_INQACCT%>" value="">
           <input type="hidden" name="hideline" value="">
           <input type="hidden" name="startLineNum" value="<%=websop.getStartLine()%>">
           <input type="hidden" name="winname" value="<%=winName%>">
           <input type="hidden" name="timestamp" value="<%=websop.getTimestamp()%>"> 
      	   <input type="hidden" name="inqord" value="">
      	   
		   <input type="hidden" name="foundlineno" value="<%=findData.getRequestFoundlineno()%>">
		   <input type="hidden" name="findsection" value="<%=findData.getRequestFindsection()%>">
		   <input type="hidden" name="findaction" value="<%=findData.getRequestFindaction()%>">
		   <input type="hidden" name="findfid" value="<%=findData.getRequestFindfid()%>">
		   <input type="hidden" name="findusoc" value="<%=findData.getRequestFindusoc()%>">
		   <input type="hidden" name="findfltd" value="<%=findData.getRequestFindfltd()%>">
		   <input type="hidden" name="finddata" value="<%=findData.getRequestFinddata()%>">
		   <input type="hidden" name="findchoicefid" value="<%=findData.getRequestFindchoicefid()%>">
		   <input type="hidden" name="findchoiceusoc" value="<%=findData.getRequestFindchoiceusoc()%>">
		   <input type="hidden" name="findchoicefltd" value="<%=findData.getRequestFindchoicefltd()%>">
		   <input type="hidden" name="findchoicedata" value="<%=findData.getRequestFindchoicedata()%>">
		   <input type="hidden" name="findreplinstoperation" value="">
           
           <input type="hidden" name="searchtext" value="<%=findData.getRequestSearchtext()%>">
	       <input type="hidden" name="screenLeft" value="<%=requestScreenLeft%>">
	       <input type="hidden" name="screenTop" value="<%=requestScreenTop%>">
	       <input type="hidden" name="foundParam" value="<%=foundInd%>">
	       <input type="hidden" name="findStatusmsg" value="<%=(findMsg==null)?"":findMsg%>">
	       <input type="hidden" name="noteCsrContent" value="">
	   	   <input type="hidden" name="noteCsrContent2" value="">
	   	   <input type="hidden" name="notePrepend" value="<%=notePrepend%>">
	       <input type="hidden" name="noteType" value="<%=noteType%>">
	       <input type="hidden" name="rp" value="">
	       <input type="hidden" name="noteType2" value="<%=noteType2%>">
	       <input type="hidden" name="rp2" value="">
<!-- Not Currently Used.
	       <input type="hidden" name="pn2" value="">
	       <input type="hidden" name="act2" value="">
	       <input type="hidden" name="fu2" value="">
-->
	       <input type="hidden" name="noteSubmit" value="">
	       <input type="hidden" name="csrScrollTop" value="">
	       <input type="hidden" name="formSubmit" value="">
	       <input type="hidden" name="popup" value="">
	       <input type="hidden" name="orderact" value="">
	       
	       <input type="hidden" name="dSalesCode" value="">
	       <input type="hidden" name="dZAP" value="">
	       <input type="hidden" name="dStn" value="null">

		   <input type="hidden" name="consDD" value="">
		   <input type="hidden" name="consED" value="">
		   <input type="hidden" name="accountList" value="">
	   <!-- Main layout table -->
       <table border=0 style="position:absolute; top:<%=IWSOP.MIH * 2%>px; left:0px">
          <tr>
            <td rowspan=2 valign=top>
                <!-- Control layout table -->
                <table border=0 class=controltable cellspacing=0>
                   <tr>
                     <td class=controlheader>&nbsp;CSR Options</td> 
                   </tr>
<%
		       if (handler.getTnFromFindAccts()!=null) {
%>
                   <tr>     
                     <td align=center style="border-left: black 1px solid;
	                       border-right:#006699 1px solid">
	                     <input type="button" class=bigbutton 
	                          name="back" value="<< AccountList" 
	                          onClick="processBack('<%=IWSOP.A_TOFINDACCTS%>')">
                     </td>
                   </tr>
<%
	           }
%>
                   <tr>
                     <td class=controlsectionlabel nowrap>&nbsp;Type</td>
                   </tr>
                       
                   <!-- CSR type -->
                   <tr>
                     <td class=controlsectiondata
                            style="border-left:black 1px solid; 
                                  border-right:#006699 1px solid">
<%
	           if (type != null && type.equals("POST")) {
%>
                       <input type=radio checked name=csrtype value="POST">None
<%             } else {  %>
                       <input type=radio name=csrtype value="POST">None
<%             }  %>
                     </td>
                   </tr>
                   <tr>
                     <td class=controlsectiondata
                           style="border-left:black 1px solid; 
                                  border-right:#006699 1px solid">
<%
			   if (type != null && type.equals("COMP")) {
%>
                         <input type=radio checked name=csrtype value="COMP">Completed
<%             } else {  %>
                         <input type=radio name=csrtype value="COMP">Completed
<%             }  %>
                     </td>
                   </tr>
                   <tr>
                     <td class=controlsectiondata
                           style="border-left:black 1px solid; 
                                  border-right:#006699 1px solid">
<%
		           if (type != null && type.equals("DIST")) {
%>
                         <input type=radio checked name=csrtype value="DIST">Distributed
<%                 } else {  %>
                         <input type=radio name=csrtype value="DIST">Distributed
<%                 }  %>
                     </td>
                   </tr>
                   <tr>
                     <td class=controlsectiondata
                          style="border-left:black 1px solid; 
                                 border-right:#006699 1px solid">
<%
		           if (type == null || type.equals("PEND")) {
%>
                         <input type=radio checked name=csrtype value="PEND">All Orders
<%                 } else {  %>
                         <input type=radio name=csrtype value="PEND">All Orders
<%                 }  %>
                    </td>
                  </tr>
                  <!-- End CSR type -->
                       
                  <tr>
                    <!-- If we have a valid due date, that is our initial value -->
                    <td class=controlsectiondata
                           style="border-left:black 1px solid; 
                                  border-right:#006699 1px solid;
                                  padding-left:5px;">As of:
<% 
   				if (dd == null || dd.equals("00-00-0000")) {
%>
				       <input type=text name="duedate" size="10" 
				           style="font-size:<%=fontSize%>px;
				                  padding-left:5px;">
<% 				} else {  %>
					   <input type=text name="duedate" value="<%=dd%>" 
						       size="10" style="font-size:<%=fontSize%>px;
					                        padding-left:5px;">
<% 				}  %>
                    </td>
                 </tr>
                 <tr>
                    <td class=controlsectionlabel align=left>&nbsp;View</td>
                 </tr>
                       
                 <!-- Display options checkboxes -->
                 <tr>
                   <td class=controlsectiondata nowrap
                        style="border-left:black 1px solid; 
                               border-right:#006699 1px solid">&nbsp;
                   </td>
                 </tr>
                 <tr>
                   <td class=controlsectiondata nowrap
                        style="border-left:black 1px solid; 
                               border-right:#006699 1px solid">
<%
			if (viewtype != null && viewtype.equals("TDVC")) {
%>
                        <input type="radio" checked name="csr_view_type" 
                           value="TDVC">Snapshot
<%			} else {  %>
                        <input type="radio" name="csr_view_type" 
                             value="TDVC">Snapshot
<% 			}  %>
                  </td>
                </tr>
                <tr>
                  <td class=controlsectiondata nowrap
                        style="border-left:black 1px solid; 
                               border-right:#006699 1px solid">
<% 
			if (viewtype == null || viewtype.equals("CAMS")) {
%>
                        <input type="radio" checked name="csr_view_type" 
                               value="CAMS">Full
<% 			} else { %>
                        <input type="radio" name="csr_view_type" 
                               value="CAMS">Full
<% 
			}
%>
                  </td>
                </tr>
                <!-- End display options checkboxes -->
                       
                <!-- Add a visual break in the control layout -->
                <tr>
                  <td align=center 
                      style="border-left: black 1px solid;
	                       border-right:#006699 1px solid">
                        <input type="button" class=largebutton
                              name="query" value="Change View" 
                              onClick="processForm1('QUERY', 1)" 
                              style="font-size:<%=fontSize%>px;">
                  </td>
                </tr>
                <tr>
                  <td align=center 
                  	  style="border-left: black 1px solid; 
                          border-right:#006699 1px solid;"> 
			           <input type="button" class=mediumbutton
				               name="refresh" value="Refresh" 
				               onClick="processForm1('REFRESH', <%=0%>)"> 
			      </td>
			    </tr>
				<tr>
			      <td align=center
				      style="border-right:#006699 1px solid; 
					         border-left: black 1px solid; 
                	         border-bottom:black 1px solid;"><br>
					    <input type="button" class=mediumbutton
					           name="notes" value="Add Note" 
					           onClick="processForm1('NOTES', <%=0%>)">
                   </td>
                 </tr>
<%
				String cstyp = websop.getWebsopUtility().getHeaderFidValue("CSTYP");
				if (cstyp != null && !cstyp.equals("")) {
%>
				 <tr>
 				   <td align=center
				       style="border-right:#006699 1px solid; 
					       border-left: black 1px solid; 
                           border-bottom:black 1px solid;"><br>
					     <input type="button" class=largebutton
					          name="csrType" value="Partial Account" 
					          onClick="processForm1('<%=IWSOP.A_MISELECTION%>', <%=0%>)">
                   </td>
                 </tr>
<%
			    }			    
			    if (cstyp != null && cstyp.equals("P")) { 
%>
				 <tr>
				   <td align=center
				       style="border-right:#006699 1px solid; 
				       border-left: black 1px solid; 
                           border-bottom:black 1px solid;"><br>
				       <input type="button" class=largebutton
				           name="csrType" value="Full Account" 
				           onClick="processForm1('<%=IWSOP.A_INQCSR%>', <%=0%>)">
                   </td>
                 </tr>
<%
			    }
			    if (csr_region!=null && csr_region.equals(IWSOP.REG_EASTERN) &&
			       (suf==null || suf.trim().equals("") || suf.trim().equals("DMD")))
			    {
%>
				 <tr>
				   <td align=center
				       style="border-right:#006699 1px solid; 
				       border-left: black 1px solid; 
                          border-bottom:black 1px solid;"><br>
				       <input type="button" class=largebutton
				           name="demandCsr" value="Demand CSR" 
				           onClick="processDemandCsr()" <%=isDemandCSR? "disabled":""%>>
                   </td>
                 </tr>
<%
                }
%>
               </table>
               <!-- End control layout table -->
               </td>

               <td>
               <!-- Section and row navigation controls -->
                <table class=navigate border=0 cellspacing=0 cellpadding=0>
                   <tr>
<%
				if (websop.getStartLine() >1) {
%>        
		                <TD width="1%" VALIGN=middle align=right>
					        <input type="image" name="prevpg" src="images/prev.GIF" 
                               alt="Previous Page" onClick="processForm1('IMAGEACTION', <%=pageStartLine%>)">
                               <input type="hidden" name="findprevline" value=<%=pageStartLine%>>
		                </TD>
<%
                }   
				if(!sfp.isLastLineOnPage(websop.getWebsopUtility().getFileLength())){
%>
		                <TD width="1%" VALIGN=middle align=left>
					        <input type="image" name="nextpg" src="images/next.GIF" 
                               alt="Next Page" onClick="processForm1('IMAGEACTION', <%=pageEndLine%>)">
					        <input type="hidden" name="findnextline" value=<%=pageEndLine+1%>>
		                </TD>
<%
                }
%>
                        <td width="1%">
                            <select name="section" id="tosection" size=1 
                                onChange="processJumpSec(this)" 
                                style="margin-left:4px; font-size:<%=fontSize%>px;">
<%
                         // TODO: store in memory
				Hashtable ht = sf.getSections();
%>
			                  <option value=" " style="font-size:<%=fontSize%>px;">
                                    To Section...</option>
<%
				String[] allSections = IWSOP.TOSECTIONS;
				for (int i=0; i<allSections.length; i++) {
			        String curkey = allSections[i];
			        if (ht.get(curkey) != null) {
				       int lineNum = ((Integer) ht.get(curkey)).intValue();
				       if (curkey.equals("S&E"))
				           curkey = "S&amp;E";
%>
                                <option value="<%=lineNum%>" 
                                    style="font-size:<%=fontSize%>px;"><%=curkey%></option>
<%
                    }
                }
%>
                        </select>
                    </td>
					
                        <TD align=left width="1%" nowrap style="font-size:<%=fontSize%>px;">
                        <B>&nbsp;&nbsp;Row <%=websop.getStartLine()%> - <%=(pageEndLine==0 ? fileBodyLength : pageEndLine)%> 
                            of <%=fileBodyLength%>  |
                        </B>
                        <td width="1%" align=right style="font-size:<%=fontSize%>px;">
                            Row:
                        </td>
                        <td width="1%">
                        <input type="text" name="jumpline" size=4 maxlength=8 
                            onKeyDown="return numbersOnly(event)" 
                            style="font-size:<%=fontSize%>px;">&nbsp;
                        </td>
                        <td>
                        <input type="button" class=microbutton name="jumpbt" value="Go" 
                            onClick="processForm1('JUMP', <%=websop.getStartLine()%>)"  
                            style="font-size:<%=fontSize%>px;">
						</td>
                   </tr>
                </table>
                <!-- End section and row navigation controls -->
                </td></tr>
                 <tr>
                    <td>
		<!-- Main WebSOP display -->
		<div style="overflow:auto; height:<%=divHeight%>px;" id="divData" 
			scrollTop='<%=scrollCsr%>' 
			onscroll="document.form1.csrScrollTop.value = 
			          document.all['divData'].scrollTop;">
		 <TABLE width="100%" class="htmlPage">
		   <TR><TD>
	         <TABLE BORDER=2 class="updatepage">
			   <TR VALIGN=top ALIGN=left>
				 <TD>
					<TABLE BORDER=0 CELLSPACING=1 CELLPADDING=1 class=updatepagenarrow>
					  <%=csrHeaderHtml%>
					</TABLE>
				 </TD>
			   </TR>
			   <TR VALIGN=top ALIGN=left>
				 <TD colspan="2">
				   <TABLE BORDER="0" CELLSPACING="0" CELLPADDING="0" class=updatepage>
					 <tbody id="single">
					   <%=csrBodyHtml%>
				     </tbody>
				   </TABLE>
				 </TD>
			   </TR>
			 </TABLE>
		   </TD></TR>
	     </TABLE>
	   </div>
	   <!-- End of Main WebSOP display -->
	</td></tr>
    </table>
    <!-- End of main layout table -->
 <!-- Yes, we have to put this piece of Javascript at the end of the page
     because, some variables will depend on JSP dynamicly to be populated
 -->
<SCRIPT type="text/javascript">
	function handleShortKeys(event){
    	if (event) {
			if(event.keyCode == 34) //pressing page-down key
			{  
           		document.form1.act.value = "IMAGEACTION";
           		document.form1.startLineNum.value = <%=pageEndLine%>;
           		doAction();
    		}
			if (event.keyCode == 33) //pressing page-up key
			{
           		document.form1.act.value = "IMAGEACTION";
           		document.form1.startLineNum.value =<%=pageStartLine%>;
           		doAction();
			}
    	}
	}
</SCRIPT>
	</FORM>
  </body>
</HTML>
<%
	websop.logTransEnd(state);
%>
