package cleanraiders.ui;

import cleanraiders.parser.SheetDownloader;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.security.GeneralSecurityException;
import java.util.List;
import java.util.Properties;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import javafx.application.Platform;
import javafx.fxml.FXML;
import javafx.scene.Cursor;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.TextField;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.KeyEvent;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.Pane;
import javafx.scene.layout.StackPane;
import javafx.scene.paint.Color;
import javafx.stage.DirectoryChooser;
import javafx.stage.Stage;

public class Controller {
    private static final Pattern pattern = Pattern.compile(".*?/spreadsheets/d/(.*?)(/|$)");
    private List<File> savedVariablesFiles;
    private String sheetId;

    @FXML
    private Pane titleBar;
    private double titleBarX;
    private double titleBarY;

    @FXML
    private ImageView btnClose;
    @FXML
    private StackPane btnCloseBackground;
    @FXML
    private ImageView btnMaximize;
    @FXML
    private ImageView btnMinimize;
    @FXML
    private ImageView wowIcon;
    @FXML
    private TextField wowPath;
    @FXML
    private TextField sheetsId;
    @FXML
    private Label lblStatus;
    @FXML
    private Button btnGo;

    @FXML
    private void initialize() {
        Platform.runLater(() -> titleBar.requestFocus());
        Properties properties = new Properties();

        String registryPath;
        try {
            properties.load(new FileReader("cleanraiders_config"));
            registryPath = properties.getProperty("wowPath");
            String sheetPath = properties.getProperty("sheetsId");
            sheetsId.setText(sheetPath);
            setSheetId(sheetPath);
        } catch (IOException e) {
            registryPath = getWowDirectoryFromRegistry();
        }

        if (registryPath == null || registryPath.isEmpty()) {
            return;
        }
        wowPath.setText(registryPath);
        setSavedVariablesDir(new File(registryPath));
    }

    @FXML
    private void handleTitleBarMousePressed(MouseEvent event) {
        titleBarX = event.getSceneX();
        titleBarY = event.getSceneY();
    }

    @FXML
    private void handleTitleBarMouseDragged(MouseEvent event) {
        Stage stage = (Stage)titleBar.getScene().getWindow();
        stage.setX(event.getScreenX() - titleBarX);
        stage.setY(event.getScreenY() - titleBarY);
    }

    @FXML
    private void handleCloseClicked() {
        try {
            Properties properties = new Properties();
            if (wowPath.getText() != null) {
                properties.put("wowPath", wowPath.getText());
            }

            if (sheetsId != null) {
                properties.put("sheetsId", sheetsId.getText());
            }

            properties.store(new FileWriter("cleanraiders_config"), "");
        } catch (IOException e) {
            System.out.println("Failed to save config.");
        }

        Platform.exit();
    }

    @FXML
    private void handleCloseEntered() {
        btnClose.getScene().setCursor(Cursor.HAND);
        btnClose.setImage(new Image("delete_sign_highlighted_32px.png"));
        btnCloseBackground.setStyle("-fx-background-color:#f04747");
    }

    @FXML
    private void handleCloseExited() {
        btnClose.getScene().setCursor(Cursor.DEFAULT);
        btnClose.setImage(new Image("delete_sign_32px.png"));
        btnCloseBackground.setStyle("-fx-background-color:#202225");
    }

    @FXML
    private void handleMaximizeEntered() {
    }

    @FXML
    private void handleMaximizeExited() {
    }

    @FXML
    private void handleMinimizeClicked() {
        Stage stage = (Stage)btnMinimize.getScene().getWindow();
        stage.setIconified(true);
    }

    @FXML
    private void handleMinimizeEntered() {
        btnMinimize.getScene().setCursor(Cursor.HAND);
        btnMinimize.setImage(new Image("horizontal_line_highlighted_32px.png"));
    }

    @FXML
    private void handleMinimizeExited() {
        btnMinimize.getScene().setCursor(Cursor.DEFAULT);
        btnMinimize.setImage(new Image("horizontal_line_32px.png"));
    }

    @FXML
    private void handleWowIconClick(MouseEvent event) {
        DirectoryChooser dirChooser = new DirectoryChooser();
        dirChooser.setTitle("Select World of Warcraft Directory");
        File dir = dirChooser.showDialog(wowIcon.getScene().getWindow());
        if (dir != null) {
            setSavedVariablesDir(dir);
            wowPath.setText(dir.getAbsolutePath());
        }
    }

    @FXML
    private void handleWowIconEntered() {
        wowIcon.getScene().setCursor(Cursor.HAND);
    }

    @FXML
    private void handleWowIconExited() {
        wowIcon.getScene().setCursor(Cursor.DEFAULT);
    }

    @FXML
    private void handleWowDirKeyTyped(KeyEvent event) {
        String text = wowPath.getCharacters() + event.getCharacter().trim();
        if (text.isEmpty()) {
            clearMessage();
        } else {
            setSavedVariablesDir(new File(text));
        }
    }

    private void setSavedVariablesDir(File dir) {
        savedVariablesFiles = null;
        if (dir != null && dir.exists()) {
            Pattern pattern = Pattern.compile(
                    Pattern.quote(dir.getAbsolutePath() + File.separator)
                            + "(_classic_|_retail_)"
                            + Pattern.quote(File.separator)
                            + "wtf" + Pattern.quote(File.separator)
                            + "account" + Pattern.quote(File.separator)
                            + ".+?"
                            + Pattern.quote(File.separator)
                            + "savedvariables"
                    , Pattern.CASE_INSENSITIVE);

            try {
                savedVariablesFiles = Files.find(dir.toPath(), 5,
                        (path, basicFileAttributes) -> pattern.matcher(path.toString()).matches())
                        .map((p) -> new File(p.toString() + File.separator + "cleanraiders.lua"))
                        .collect(Collectors.toList());

                if (savedVariablesFiles.isEmpty()) {
                    setErrorMessage("Folder does not contain World of Warcraft!");
                } else {
                    clearMessage();
                }
            } catch (IOException e) {
                setErrorMessage(e.getMessage());
            }

        } else {
            setErrorMessage("WoW folder does not exist!");
        }
    }

    @FXML
    private void handleChangedSheetsId(KeyEvent event) {
        setSheetId(sheetsId.getCharacters() + event.getCharacter().trim());
    }

    private void setSheetId(String text) {
        if (text != null && !text.isEmpty()) {
            if (text.length() == 44) {
                sheetId = text;
                clearMessage();
            } else {
                if (text.length() > 44) {
                    Matcher matcher = pattern.matcher(text);
                    if (matcher.find() && matcher.groupCount() >= 1 && matcher.group(1).length() == 44) {
                        sheetId = matcher.group(1);
                        clearMessage();
                        return;
                    }
                }

                sheetId = null;
                setErrorMessage("Not a valid spreadsheet URL or ID!");
            }
        } else {
            sheetId = null;
            clearMessage();
        }
    }

    @FXML
    private void handleGoClick(MouseEvent event) {
        if (savedVariablesFiles == null) {
            setErrorMessage("You must select your WoW folder!");
            return;
        }

        if (sheetId == null) {
            setErrorMessage("You must select a spreadsheet!");
            return;
        }

        if (isWowRunning()) {
            setErrorMessage("Close WoW first before updating addon data!");
            return;
        }

        this.setDownloadingMessage("Attempting to download sheet...");
        Platform.runLater(() -> {
            try {
                SheetDownloader.downloadSheet(savedVariablesFiles, sheetId);
                setSuccessMessage("Sheet successfully downloaded!");
            } catch (GeneralSecurityException | IOException e) {
                setErrorMessage(e.getMessage());
            }
        });
    }

    private void clearMessage() {
        lblStatus.setText("");
    }

    private void setDownloadingMessage(String message) {
        lblStatus.setTextFill(Color.web("#E0E340"));
        lblStatus.setText(message);
    }

    private void setSuccessMessage(String message) {
        lblStatus.setTextFill(Color.web("#0EA366"));
        lblStatus.setText(message);
    }

    private void setErrorMessage(String message) {
        lblStatus.setTextFill(Color.web("#EF2B2B"));
        lblStatus.setText(message);
    }

    private static boolean isWowRunning() {
        try {
            if (!System.getProperty("os.name").toLowerCase().contains("win")) {
                return false;
            }

            ProcessBuilder processBuilder = new ProcessBuilder("tasklist.exe", "/fi", "\"WINDOWTITLE eq World of Warcraft\"", "/fo", "csv");
            Process process = processBuilder.start();
            try (BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                int lineCount = 0;

                do {
                    if (bufferedReader.readLine() == null) {
                        return false;
                    }

                    ++lineCount;
                } while (lineCount <= 1);

                return true;
            }
        } catch (IOException e) {
            return false;
        }
    }

    private static String getWowDirectoryFromRegistry() {
        try {
            if (!System.getProperty("os.name").toLowerCase().contains("win")) {
                return null;
            }

            Pattern pattern = Pattern.compile("\\s*InstallPath\\s*REG_SZ\\s*(.*?)\\\\$");
            ProcessBuilder processBuilder = new ProcessBuilder(
                    "reg.exe", "query", "\"HKLM\\SOFTWARE\\WOW6432Node\\Blizzard Entertainment\\World of Warcraft\"", "/v", "\"InstallPath\"", "/t", "REG_SZ");
            Process process = processBuilder.start();
            try (BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String s;
                do {
                    String line;
                    if ((line = bufferedReader.readLine()) == null) {
                        return null;
                    }

                    s = line.trim();
                } while (!s.startsWith("InstallPath"));

                Matcher matcher = pattern.matcher(s);
                if (!matcher.matches()) {
                    return null;
                }
                String match = matcher.group(1);
                return match.substring(0, match.lastIndexOf('\\'));
            }
        } catch (IOException e) {
            return null;
        }
    }
}
