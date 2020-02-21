package cleanraiders.parser;

import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.JsonFactory;
import com.google.api.client.json.jackson2.JacksonFactory;
import com.google.api.services.sheets.v4.Sheets;
import com.google.api.services.sheets.v4.model.SheetProperties;
import com.google.api.services.sheets.v4.model.Spreadsheet;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.security.GeneralSecurityException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

public class SheetDownloader {
    private static final String APPLICATION_NAME = "clean raiders";
    private static final JsonFactory JSON_FACTORY = JacksonFactory.getDefaultInstance();
    private static final String API_KEY = new String(new byte[] {
            0x41, 0x49, 0x7A, 0x61, 0x53,
            0x79, 0x42, 0x67, 0x64, 0x56,
            0x34, 0x49, 0x42, 0x2D, 0x57,
            0x30, 0x71, 0x65, 0x6C, 0x55,
            0x56, 0x41, 0x78, 0x37, 0x52,
            0x64, 0x62, 0x62, 0x61, 0x55,
            0x37, 0x72, 0x38, 0x78, 0x78,
            0x31, 0x46, 0x6D, 0x63
    });

    public static void downloadSheet(List<File> outputFiles, String spreadsheetId) throws IOException, GeneralSecurityException {
        final NetHttpTransport HTTP_TRANSPORT = GoogleNetHttpTransport.newTrustedTransport();
        Sheets service = new Sheets.Builder(HTTP_TRANSPORT, JSON_FACTORY, null)
                .setApplicationName(APPLICATION_NAME)
                .build();

        Spreadsheet spreadsheet = service.spreadsheets()
                .get(spreadsheetId)
                .setKey(API_KEY)
                .execute();

        List<List<List<Object>>> allValues = spreadsheet.getSheets().stream()
                .filter(sheet -> {
                    SheetProperties properties = sheet.getProperties();
                    return properties != null
                            && (properties.getHidden() == null || !properties.getHidden())
                            && (!properties.getTitle().equals("README") && !properties.getTitle().equals("Template"));
                })
                .map(sheet -> {
                    String range = sheet.getProperties().getTitle() + "!A1:J";
                    try {
                        return service.spreadsheets().values()
                                .get(spreadsheetId, range)
                                .setKey(API_KEY)
                                .execute()
                                .getValues();
                    } catch (IOException e) {
                        return null;
                    }
                })
                .collect(Collectors.toList());

        // parse to Lua
        String dateString = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss").format(LocalDateTime.now());
        String newEntry = new SheetParser().parse(dateString, allValues);
        List<String> corruptedFiles = new ArrayList<>();

        for (File outputFile : outputFiles) {
            String prefix;
            String suffix;
            if (outputFile.exists()) {
                Pattern pattern = Pattern.compile("(.*?cleanraidersDB.*?=.*?\\{)(.*?)$", Pattern.DOTALL);
                Matcher matcher = pattern.matcher(new String(Files.readAllBytes(outputFile.toPath()), StandardCharsets.UTF_8));
                if (!matcher.find() || matcher.groupCount() != 2) {
                    corruptedFiles.add(outputFile.getAbsolutePath());
                    continue;
                }

                prefix = matcher.group(1);
                suffix = matcher.group(2);
            } else {
                prefix = "cleanraidersDB={";
                suffix = "}";
            }

            try (OutputStreamWriter outputStreamWriter =
                         new OutputStreamWriter(new FileOutputStream(outputFile), StandardCharsets.UTF_8)) {
                outputStreamWriter.write(prefix);
                outputStreamWriter.write(newEntry);
                outputStreamWriter.write(suffix);
            }
        }

        if (!corruptedFiles.isEmpty()) {
            throw new IOException("File " + corruptedFiles.get(0) + " is corrupted. Delete it.");
        }
    }
}
