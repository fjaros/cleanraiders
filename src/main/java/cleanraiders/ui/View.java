package cleanraiders.ui;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.geometry.Rectangle2D;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.image.Image;
import javafx.stage.Screen;
import javafx.stage.Stage;
import javafx.stage.StageStyle;

public class View extends Application {

    public void start(Stage primaryStage) throws Exception {
        Parent root = FXMLLoader.load(ClassLoader.getSystemClassLoader().getResource("ui.fxml"));
        primaryStage.getIcons().add(new Image("cleanlogo.png"));
        primaryStage.initStyle(StageStyle.UNDECORATED);
        primaryStage.setTitle("<clean> raiders");
        primaryStage.setScene(new Scene(root));
        primaryStage.show();
        Rectangle2D visualBounds = Screen.getPrimary().getVisualBounds();
        primaryStage.setX((visualBounds.getWidth() - primaryStage.getWidth()) / 2.0);
        primaryStage.setY((visualBounds.getHeight() - primaryStage.getHeight()) / 2.0);
    }

    public static void main(String[] args) {
        launch(args);
    }
}
