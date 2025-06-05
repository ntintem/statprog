/*
*****************************************************************************************************************
Project		 : StatProg
SAS file name: toc.sas
File location: /statprog/macro/toc.sas
*****************************************************************************************************************
Purpose: Project setup program.
Author: Mazi Ntintelo
Creation Date: 2024-06-05
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/
proc groovy;
	add classpath="~\pdfbox-app-3.0.2.jar";
	submit "&pathInPdfDocument" "&fileOut" "%sysfunc(pathname(work))\Visits.csv" "%sysfunc(pathname(work))\Forms.csv";
		import java.util.*;
		import java.util.regex.*;
		import java.awt.Color;
		import java.lang.Exception;
		import java.io.IOException;
		import java.io.FileWriter;
		import org.apache.pdfbox.pdmodel.*;
		import org.apache.pdfbox.pdmodel.interactive.documentnavigation.outline.*;
		import org.apache.pdfbox.Loader;
		import org.apache.pdfbox.text.*;
		import org.apache.pdfbox.pdmodel.interactive.annotation.*;
		import org.apache.pdfbox.pdmodel.graphics.color.PDColor;
		import org.apache.pdfbox.pdmodel.font.*;
		import org.apache.pdfbox.pdmodel.font.encoding.*;
		import org.apache.pdfbox.pdmodel.interactive.action.*;
		import org.apache.pdfbox.pdmodel.common.*;
		import org.apache.pdfbox.pdmodel.interactive.documentnavigation.destination.*;

		public class TableOfContentsGenerator {
			//Constants
			public static final int FIRST_PAGE=0;
			public static final int PDF_FILE_INDEX=0;
			public static final int FILE_NAME_INDEX=1;
			public static final int VISITS_METADATA_FILE_INDEX=2;
			public static final int FORMS_METADATA_FILE_INDEX=3;
			public static final String COURIER_FONT = "~\\TableOfContents\\Fonts\\cour.ttf";

			//Instance variables
			private PDDocument annotedCaseReportForm;
			private ArrayList<PDOutlineItem> mainBookmarks;
			private ArrayList<PDPage> pages;
			private LinkedHashMap<String, LinkedHashMap<String, PDPage>> visits;
        	private LinkedHashMap<String, LinkedHashMap<String, PDPage>> forms;
			private PDPage firstPage;

			public static void main(String[] args) {
				String pdfFile=args[PDF_FILE_INDEX];
				String outFile=args[FILE_NAME_INDEX];
				String visitsMetadataFile=args[VISITS_METADATA_FILE_INDEX];
				String formatsMetadataFile=args[FORMS_METADATA_FILE_INDEX];
				TableOfContentsGenerator tableOfContents = new TableOfContentsGenerator(pdfFile);
				HashMap<String, Integer> orderMap = tableOfContents.readMetadata(visitsMetadataFile, tableOfContents.visits);
				tableOfContents.readMetadata(formatsMetadataFile, tableOfContents.forms);
				tableOfContents.readPdf(orderMap);
				tableOfContents.bookmarks("Visit", tableOfContents.visits);
				tableOfContents.bookmarks("Form", tableOfContents.forms);
				tableOfContents.printTableOfContents("Visit", tableOfContents.visits);
				tableOfContents.printTableOfContents("Form", tableOfContents.forms);
				tableOfContents.setNewDestinationForMainBookmarks();
				tableOfContents.setFirstPageAsLandingPage();
				tableOfContents.closePdf(outFile);
			}
			
			public TableOfContentsGenerator(String filename){
				annotedCaseReportForm = Loader.loadPDF(new File(filename));
				pages = new ArrayList<PDPage>();
				mainBookmarks = new ArrayList<PDOutlineItem>();
				visits = new LinkedHashMap<String, LinkedHashMap<String, PDPage>>();
				forms = new LinkedHashMap<String, LinkedHashMap<String, PDPage>>();
				firstPage = annotedCaseReportForm.getPage(FIRST_PAGE);
			}

			// Default constructor not used, but kept for compilation purposes
			public TableOfContentsGenerator(){

			}

			private HashMap<String, Integer> readMetadata(String file, LinkedHashMap<String, LinkedHashMap<String, PDPage>> map){
				BufferedReader br = null;
				String line = null;
				HashMap<String, Integer> orderMap = new HashMap<String, Integer>();
				int order = 0;
				try{
					br = new BufferedReader(new FileReader(new File(file)));
					br.readLine();
					while((line = br.readLine()) != null){
						map.put(line, new LinkedHashMap<String, PDPage>());
						orderMap.put(line, ++order);
					}
				}catch(IOException ex){
					ex.printStackTrace();
				}finally{
					closeReader(br);
				}
				return orderMap;
			}

			private static void closeReader(BufferedReader br){
				try{
					if (br != null){
						br.close();
					}
				}catch(IOException ex){
					ex.printStackTrace();
				}
			}

			private void readPdf(HashMap<String, Integer> orderMap){
            	PDFTextStripper stripper = new PDFTextStripper();
				for (int i=0; i < annotedCaseReportForm.getNumberOfPages(); i++){
					stripper.setStartPage(i + 1);
					stripper.setEndPage(i + 1);
					stripper.setLineSeparator("`");
           			String text = stripper.getText(annotedCaseReportForm);
					String[] lines = text.split("`");
					validateExtractedText(lines, i, orderMap);
				}
			}
 
			private void validateExtractedText(String[] lines, int page, HashMap<String, Integer> orderMap){
				for(int i=0; i < lines.length; i++){
					Matcher matcher = Pattern.compile("\\bat\\b").matcher(lines[i]);
					if (matcher.find()){
						String form = lines[i].substring(0, matcher.start() - 1);
						String[] visits = lines[i].substring(matcher.start() + 3).split(",");
						fillMaps(visits, form, annotedCaseReportForm.getPage(page), orderMap);
					}
				}
			}

			private static void remapVisits(String[] visits, HashMap<String, Integer> orderMap){
				for(int i=0; i < visits.length; i++){
					visits[i] = visits[i] + "`" + (orderMap.containsKey(visits[i]) ? orderMap.get(visits[i]) : "999");
        		}
			}

			private static void sortVisits(String[] visits) {
				Comparator compare = new Comparator<String>(){
         			public int compare(String str1, String str2){
               		return Integer.valueOf(str1.split("`")[1])
                                  .compareTo(Integer.valueOf(str2.split("`")[1]));
        		 	}
     			};
				Arrays.sort(visits, compare);
			}

    		private void fillMaps(String[] visits, String form, PDPage page, HashMap<String, Integer> orderMap){
				remapVisits(visits, orderMap);
				sortVisits(visits);
         		for(int i=0; i < visits.length; i++){
					visits[i] = visits[i].split("`")[0];
					if(!(this.visits.containsKey(visits[i]) && this.forms.containsKey(form))){
						continue;
					}
					this.visits.get(visits[i]).put(form, page);
					this.forms.get(form).put(visits[i], page);
        		}
   			 } 

			private void bookmarks(String title, LinkedHashMap<String, LinkedHashMap<String, PDPage>> map){
				PDOutlineItem mainBookmark = new PDOutlineItem();
				mainBookmark.setTitle(title);
				mainBookmark.setDestination(annotedCaseReportForm.getPage(0));
				PDOutlineItem bookmark;
				PDOutlineItem nestedBookmark;
				mainBookmarks.add(mainBookmark);
				for(Map.Entry<String, LinkedHashMap<String, PDPage>> parentEntry : map.entrySet()){
					boolean first = true;
					bookmark = new PDOutlineItem();
					bookmark.setTitle(parentEntry.getKey());
					mainBookmark.addLast(bookmark); 
					for(Map.Entry<String, LinkedHashMap<String, PDPage>> childEntry : parentEntry.getValue().entrySet()){
						nestedBookmark = new PDOutlineItem();
						nestedBookmark.setTitle(childEntry.getKey());
						nestedBookmark.setDestination(childEntry.getValue());  
						bookmark.addLast(nestedBookmark);
						if (first){
							bookmark.setDestination(childEntry.getValue());  
							first=false;
						}
					}
       			}
				addMainBookmarksToDocumentOutline();
			}

			private void setNewDestinationForMainBookmarks(){
				for(int i=0; i < mainBookmarks.size(); i++){
					mainBookmarks.get(i).setDestination(pages.get(i));
				}
			}

			private void addMainBookmarksToDocumentOutline(){
				PDDocumentOutline outline = new PDDocumentOutline();
				for(PDOutlineItem item: mainBookmarks){
					outline.addLast(item);
				}
				annotedCaseReportForm.getDocumentCatalog().setDocumentOutline(outline);
			}

			private void printTableOfContents(String title, LinkedHashMap<String, LinkedHashMap<String, PDPage>> map) {
				PDPage page = null;
				PDPageContentStream contentStream = null;
				PDTrueTypeFont font = null;
				float fontSize = 10;
				float leading = 1.5f * fontSize;
				float margin=100;
				float yPosition = new PDPage().getMediaBox().getHeight() - margin;
				boolean first = true;
				PDBorderStyleDictionary borderStyle = new PDBorderStyleDictionary(); 
				borderStyle.setWidth(0);
				for(Map.Entry<String, LinkedHashMap<String, PDPage>> parentEntry : map.entrySet()){
					boolean flag=true;
					for(Map.Entry<String, LinkedHashMap<String, PDPage>> childEntry : parentEntry.getValue().entrySet()){
						if (first || yPosition - leading < margin) {
							page = new PDPage();
							annotedCaseReportForm.getPages().insertBefore(page, firstPage);
							if (contentStream != null) {
								contentStream.endText();
								contentStream.close();
								yPosition = new PDPage().getMediaBox().getHeight() - margin;
							}
							contentStream = new PDPageContentStream(annotedCaseReportForm, page);
							font = PDTrueTypeFont.load(annotedCaseReportForm, new File(COURIER_FONT), WinAnsiEncoding.INSTANCE);
							contentStream.beginText();
							contentStream.setFont(font, fontSize);
							contentStream.setLeading(leading);
							contentStream.newLineAtOffset(margin, yPosition);
						}
						contentStream.setNonStrokingColor(Color.BLACK);
						if (first) {
							pages.add(page);
							contentStream.showText(title);
							contentStream.newLine();
							yPosition -= leading;
						}
						if (flag) {
							contentStream.showText("     ".concat(parentEntry.getKey()));
							contentStream.newLine();
							yPosition -= leading;
							flag=false;
						}
						contentStream.setNonStrokingColor(Color.BLUE);
						String showText = "          ".concat(childEntry.getKey());
						contentStream.showText(showText);
						contentStream.newLine();
						PDAnnotationLink link = new PDAnnotationLink();
						link.setBorderStyle(borderStyle);
						PDRectangle position = new PDRectangle(margin, yPosition, (float)(font.getStringWidth(showText) / 1000 * fontSize), leading);
						link.setRectangle(position);
						PDPageXYZDestination destination = new PDPageXYZDestination();
						destination.setPage(childEntry.getValue());
						PDActionGoTo action = new PDActionGoTo();
						action.setDestination(destination);
						link.setAction(action);
						page.getAnnotations().add(link);
						yPosition -= leading;
						first = false;
					}
				}
				contentStream.endText();
				contentStream.close();
			}

			private void closePdf(String fileOut){
				annotedCaseReportForm.save(fileOut);
				annotedCaseReportForm.close();
			}

			private void setFirstPageAsLandingPage(){
				PDPageDestination destination = new PDPageFitDestination();
				destination.setPage(annotedCaseReportForm.getPage(FIRST_PAGE));
				PDActionGoTo action = new PDActionGoTo();
				action.setDestination(destination);
				annotedCaseReportForm.getDocumentCatalog().setOpenAction(action);
			}
		}
	endsubmit;
quit;

