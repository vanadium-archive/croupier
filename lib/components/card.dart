import '../logic/card.dart' as logic_card;
import 'package:sky/widgets.dart' as widgets;
import 'package:sky/theme/colors.dart' as colors;

class Card extends widgets.Component {
  logic_card.Card card;
  bool faceUp;

  Card(this.card, this.faceUp);

  widgets.Widget build() {
    return new widgets.Listener(
      child: new widgets.Container(
        child: new widgets.Container(
          decoration: new widgets.BoxDecoration(
            border: new widgets.Border.all(
              width: 3.0,
              color: colors.Red[500]
            ),
            backgroundColor: colors.Brown[500]
          ),
          child: new widgets.Flex([
            imageFromCard(card, faceUp),
            new widgets.Text('removethis')
          ], direction: widgets.FlexDirection.vertical)
        )
      )
    );
  }

  static widgets.Widget imageFromCard(logic_card.Card c, bool faceUp) {
    String imageName = "${c.deck}/${faceUp ? 'up' : 'down'}/${c.identifier}.png";
    return new widgets.NetworkImage(src: imageName);
  }
}
